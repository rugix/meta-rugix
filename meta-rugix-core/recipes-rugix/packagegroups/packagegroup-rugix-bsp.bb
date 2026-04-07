SUMMARY = "Rugix BSP packages."
inherit packagegroup
PACKAGE_ARCH = "${MACHINE_ARCH}"

RDEPENDS:${PN} = "\
    rugix-bootstrapping-conf \
    rugix-system-conf \
    util-linux-sfdisk \
    e2fsprogs-mke2fs \
"
