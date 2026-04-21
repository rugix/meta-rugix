SUMMARY = "Initramfs that sets up a dm-verity root filesystem before pivoting"
LICENSE = "MIT"

PACKAGE_INSTALL = " \
    initramfs-framework-base \
    initramfs-module-udev \
    verity-initramfs-module \
    ${VIRTUAL-RUNTIME_base-utils} \
"

ROOTFS_BOOTSTRAP_INSTALL = ""

IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""

IMAGE_FSTYPES = "${INITRAMFS_FSTYPES}"
# Drop the ext4+verity fstypes that meta-rugix-nxp-imx-uboot's layer.conf
# appends for the main rootfs. An initramfs only needs the cpio archive;
# without this, it would also build a ~50 MB ext4+hash-tree variant of
# itself that never gets used.
IMAGE_FSTYPES:remove = "ext4 verity"

# Deploy as ${IMAGE_BASENAME}-${MACHINE}.cpio.gz (no ".rootfs" suffix),
# which is where kernel-fitimage.bbclass looks for the initramfs cpio.
IMAGE_NAME_SUFFIX = ""

inherit core-image

BAD_RECOMMENDATIONS += "busybox-syslog"
