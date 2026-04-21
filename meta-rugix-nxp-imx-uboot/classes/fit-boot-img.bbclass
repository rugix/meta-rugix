# Wrap the kernel FIT in a FAT image (${IMAGE_LINK_NAME}.boot.img) so it can
# live on a raw boot slot and be updated as a single block-level write. The FAT
# image is sized to just fit the FIT plus enough slack for the FAT's own
# metadata.
#
# In verified-boot builds, this class also consumes the verity sidecar produced
# by image_types_verity, stamps the dm-verity root hash into the FIT's
# /bootargs (using the padding reserved via UBOOT_MKIMAGE_DTCOPTS=-p 2000), and
# re-signs the FIT when UBOOT_SIGN_ENABLE=1. Writing to IMGDEPLOYDIR (rather
# than DEPLOY_DIR_IMAGE directly) lets do_image_complete promote the result to
# DEPLOY_DIR_IMAGE via the normal sstate mechanism.

DEPENDS += "u-boot-tools-native dtc-native dosfstools-native mtools-native"

python do_fit_boot_img() {
    import os
    import shutil
    import subprocess

    imgdeploydir = d.getVar("IMGDEPLOYDIR")
    # DEPLOY_DIR_IMAGE for the kernel FIT (produced by virtual/kernel:do_deploy,
    # which writes straight to DEPLOY_DIR_IMAGE).
    deploy_dir = d.getVar("DEPLOY_DIR_IMAGE")
    image_link = d.getVar("IMAGE_LINK_NAME")
    verity_fstype = d.getVar("VERITY_IMAGE_FSTYPE") or "ext4"
    # Verity params sidecar deposited by image_types_verity.bbclass next to
    # the verity image itself.
    params_file = os.path.join(
        imgdeploydir, image_link + "." + verity_fstype + ".verity-params"
    )
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

    # kernel-fitimage.bbclass deploys the initramfs-carrying FIT as
    # fitImage-${INITRAMFS_IMAGE_NAME}-${KERNEL_FIT_LINK_NAME}, where
    # KERNEL_FIT_LINK_NAME defaults to ${MACHINE}. That name isn't
    # visible in image recipe scope, so use MACHINE directly.
    initramfs_image_name = d.getVar("INITRAMFS_IMAGE_NAME")
    machine = d.getVar("MACHINE")
    src_fit = os.path.join(deploy_dir, "fitImage-{}-{}".format(initramfs_image_name, machine))
    if not os.path.exists(src_fit):
        bb.fatal("Kernel FIT not found at %s" % src_fit)
    workdir = os.path.join(d.getVar("B"), "fit-boot-img")
    os.makedirs(workdir, exist_ok=True)
    staged_fit = os.path.join(workdir, "fitImage")
    shutil.copyfile(src_fit, staged_fit)

    # image_types_verity.bbclass formats the hash tree with --no-superblock,
    # so the initramfs needs the full geometry (not just the root hash) at
    # boot time to reconstruct the dm-verity mapping.
    bootargs = (
        "roothash={roothash} roothashoffset={offset} "
        "rootdatablocks={blocks} rootblocksize={bs} rootsalt={salt}"
    ).format(roothash=root_hash, offset=hash_offset,
             blocks=data_blocks, bs=block_size, salt=salt)
    subprocess.check_call([
        "fdtput", "-t", "s", staged_fit, "/", "bootargs", bootargs,
    ])

    if d.getVar("UBOOT_SIGN_ENABLE") == "1":
        sign_keydir = d.getVar("UBOOT_SIGN_KEYDIR")
        sign_keyname = d.getVar("UBOOT_SIGN_KEYNAME") or "dev"
        key_path = os.path.join(sign_keydir or "", sign_keyname + ".key")
        if not os.path.isfile(key_path):
            bb.fatal("UBOOT_SIGN_ENABLE=1 but {} not found. Run 'just gen-signing-keys'.".format(key_path))
        subprocess.check_call([
            "uboot-mkimage", "-F", "-k", sign_keydir, "-r", staged_fit,
        ])

    # Size the FAT image to fit the (possibly re-signed) FIT plus slack for
    # the filesystem's own metadata: round up to the next MiB and add another
    # MiB for the boot sector, FAT tables, and root dir.
    fit_size = os.path.getsize(staged_fit)
    mib = 1024 * 1024
    boot_size_bytes = ((fit_size + mib - 1) // mib) * mib + mib
    boot_size_kib = boot_size_bytes // 1024

    boot_image = os.path.join(workdir, "boot.img")
    # mkfs.vfat -C refuses to overwrite; nuke any leftover from a prior run.
    if os.path.exists(boot_image):
        os.remove(boot_image)
    subprocess.check_call([
        "mkfs.vfat", "-C", "-n", "BOOT", boot_image, str(boot_size_kib),
    ])
    subprocess.check_call([
        "mcopy", "-i", boot_image, staged_fit, "::fitImage",
    ])
    shutil.copyfile(boot_image, os.path.join(imgdeploydir, image_link + ".boot.img"))
}

do_fit_boot_img[depends] += "virtual/kernel:do_deploy"

# Only wire the task for image recipes that actually build a verity image.
# Inherited classes cannot know which recipe they land in, so an initramfs
# or other non-rootfs image would otherwise hit the sidecar-not-found fatal.
python __anonymous() {
    if 'verity' in (d.getVar('IMAGE_FSTYPES') or '').split():
        bb.build.addtask('do_fit_boot_img', 'do_image_wic', 'do_image_verity', d)
}
