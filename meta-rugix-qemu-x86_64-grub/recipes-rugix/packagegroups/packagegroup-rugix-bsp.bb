SUMMARY = "Rugix BSP packages for QEMU x86_64 with GRUB."
inherit packagegroup
PACKAGE_ARCH = "${MACHINE_ARCH}"

RDEPENDS:${PN} = "\
    rugix-bootstrapping-conf \
    rugix-system-conf \
    util-linux-sfdisk \
    e2fsprogs-mke2fs \
    kernel-image \
"
