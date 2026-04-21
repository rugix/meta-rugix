# Produce the two files RUGIX_SLOTS names:
#   boot   -> rugix-boot.img  (FAT image containing the kernel FIT)
#   system -> rootfs.verity   (ext4 + dm-verity hash tree)
#
# kernel-fitimage.bbclass assembles and signs the kernel FIT at kernel
# time; image_types_verity.bbclass (meta-oe) produces the verity rootfs
# and a .verity-params sidecar. We consume those and at image time:
# stamp the roothash into the FIT's /bootargs (into the padding from
# UBOOT_MKIMAGE_DTCOPTS=-p 2000), re-sign if UBOOT_SIGN_ENABLE=1 (same
# key, so the pubkey already in u-boot.dtb still matches), and wrap the
# FIT in a FAT image the size of the boot partition so slot updates are
# one atomic block-level write.

DEPENDS += "u-boot-tools-native dtc-native dosfstools-native mtools-native"

python do_rugix_slot_payloads() {
    import os
    import shutil
    import subprocess

    imgdeploydir = d.getVar("IMGDEPLOYDIR")
    deploy_dir = d.getVar("DEPLOY_DIR_IMAGE")
    image_link = d.getVar("IMAGE_LINK_NAME")
    verity_fstype = d.getVar("VERITY_IMAGE_FSTYPE") or "ext4"
    verity_suffix = d.getVar("VERITY_IMAGE_SUFFIX") or ".verity"
    # image_types_verity.bbclass deposits sidecars next to the verity
    # image at ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.${VERITY_IMAGE_FSTYPE}{suffix,-info,-params}.
    base = os.path.join(imgdeploydir, image_link + "." + verity_fstype)
    params_file = base + ".verity-params"
    if not os.path.exists(params_file):
        bb.fatal("verity params not found at %s (is 'verity' in IMAGE_FSTYPES?)" % params_file)
    params = {}
    with open(params_file) as f:
        for line in f:
            if "=" in line:
                k, _, v = line.strip().partition("=")
                params[k] = v
    root_hash = params.get("VERITY_ROOT_HASH")
    data_blocks = int(params.get("VERITY_DATA_BLOCKS", "0"))
    block_size = int(params.get("VERITY_DATA_BLOCK_SIZE", "0"))
    salt = params.get("VERITY_SALT")
    if not root_hash or not data_blocks or not block_size or not salt:
        bb.fatal("verity params file %s is missing required fields" % params_file)
    hash_offset = data_blocks * block_size
    bb.note("Root hash %s, hash offset %d" % (root_hash, hash_offset))

    verity_file = os.path.realpath(base + verity_suffix)
    shutil.copyfile(verity_file, os.path.join(deploy_dir, "rootfs.verity"))

    # kernel-fitimage.bbclass deploys the initramfs-carrying FIT as
    # fitImage-${INITRAMFS_IMAGE_NAME}-${KERNEL_FIT_LINK_NAME}, where
    # KERNEL_FIT_LINK_NAME defaults to ${MACHINE}. That name isn't
    # visible in image recipe scope, so use MACHINE directly.
    initramfs_image_name = d.getVar("INITRAMFS_IMAGE_NAME")
    machine = d.getVar("MACHINE")
    src_fit = os.path.join(deploy_dir, "fitImage-{}-{}".format(initramfs_image_name, machine))
    if not os.path.exists(src_fit):
        bb.fatal("Kernel FIT not found at %s" % src_fit)
    workdir = os.path.join(d.getVar("B"), "rugix-slot-payloads")
    os.makedirs(workdir, exist_ok=True)
    rugix_fit = os.path.join(workdir, "rugix-fitImage")
    shutil.copyfile(src_fit, rugix_fit)

    # image_types_verity.bbclass formats the hash tree with --no-superblock,
    # so the initramfs needs the full geometry (not just the root hash) at
    # boot time to reconstruct the dm-verity mapping.
    bootargs = (
        "roothash={roothash} roothashoffset={offset} "
        "rootdatablocks={blocks} rootblocksize={bs} rootsalt={salt}"
    ).format(roothash=root_hash, offset=hash_offset,
             blocks=data_blocks, bs=block_size, salt=salt)
    subprocess.check_call([
        "fdtput", "-t", "s", rugix_fit, "/", "bootargs", bootargs,
    ])

    if d.getVar("UBOOT_SIGN_ENABLE") == "1":
        sign_keydir = d.getVar("UBOOT_SIGN_KEYDIR")
        sign_keyname = d.getVar("UBOOT_SIGN_KEYNAME") or "dev"
        key_path = os.path.join(sign_keydir or "", sign_keyname + ".key")
        if not os.path.isfile(key_path):
            bb.fatal("UBOOT_SIGN_ENABLE=1 but {} not found. Run 'just gen-signing-keys'.".format(key_path))
        subprocess.check_call([
            "uboot-mkimage", "-F", "-k", sign_keydir, "-r", rugix_fit,
        ])

    # Wrap the (possibly signed) FIT in a FAT image sized to the boot
    # partition. Slot updates write the whole FAT image at once, so the
    # update is atomic at the block layer; U-Boot reads just the file.
    boot_size_kib = iec_to_kib(d.getVar("RUGIX_BOOT_SIZE") or "96MiB")
    boot_image = os.path.join(workdir, "rugix-boot.img")
    # mkfs.vfat -C refuses to overwrite; nuke any leftover from a prior run.
    if os.path.exists(boot_image):
        os.remove(boot_image)
    subprocess.check_call([
        "mkfs.vfat", "-C", "-n", "RUGIXBOOT", boot_image, str(boot_size_kib),
    ])
    subprocess.check_call([
        "mcopy", "-i", boot_image, rugix_fit, "::fitImage",
    ])
    shutil.copyfile(boot_image, os.path.join(deploy_dir, "rugix-boot.img"))
}

def iec_to_kib(size):
    """Parse an IEC size string like '96MiB' or '4GiB' and return KiB."""
    s = size.strip().rstrip("iB").rstrip()
    if not s or not s[-1].isalpha():
        return int(s)
    mult = {"K": 1, "M": 1024, "G": 1024 * 1024}[s[-1].upper()]
    return int(s[:-1]) * mult

do_rugix_slot_payloads[depends] += "virtual/kernel:do_deploy"

# Only wire the task for image recipes that actually build a verity image.
# Inherited classes cannot know which recipe they land in, so an initramfs
# or other non-rootfs image would otherwise hit the sidecar-not-found fatal.
python __anonymous() {
    if 'verity' in (d.getVar('IMAGE_FSTYPES') or '').split():
        bb.build.addtask('do_rugix_slot_payloads', 'do_image_wic', 'do_image_verity', d)
}
