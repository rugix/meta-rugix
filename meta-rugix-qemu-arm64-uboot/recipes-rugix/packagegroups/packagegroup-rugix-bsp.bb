SUMMARY = "Rugix BSP packages for QEMU ARM64 with U-Boot."
inherit packagegroup

RDEPENDS:${PN} = "\
    rugix-bootstrapping-conf \
    rugix-system-conf \
    util-linux-sfdisk \
    e2fsprogs-mke2fs \
    kernel-image \
    u-boot-default-env \
    u-boot-fw-utils \
"
