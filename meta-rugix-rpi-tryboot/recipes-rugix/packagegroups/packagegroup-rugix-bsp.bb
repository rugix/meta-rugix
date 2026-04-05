SUMMARY = "Rugix BSP packages for Raspberry Pi with Tryboot."
inherit packagegroup

RDEPENDS:${PN} = "\
    rugix-bootstrapping-conf \
    rugix-system-conf \
    util-linux-sfdisk \
    e2fsprogs-mke2fs \
"
