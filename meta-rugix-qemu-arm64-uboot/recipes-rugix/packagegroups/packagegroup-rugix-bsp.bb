SUMMARY = "Rugix BSP packages for QEMU ARM64 with U-Boot."
inherit packagegroup
PACKAGE_ARCH = "${MACHINE_ARCH}"

RDEPENDS:${PN} = "\
    rugix-bootstrapping-conf \
    rugix-system-conf \
    util-linux-sfdisk \
    e2fsprogs-mke2fs \
    kernel-image \
    u-boot-default-env \
    u-boot-fw-utils \
"
