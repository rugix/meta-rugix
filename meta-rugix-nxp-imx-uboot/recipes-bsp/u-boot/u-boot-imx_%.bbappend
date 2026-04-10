FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:imx-nxp-bsp = " \
    file://boot.cmd \
    file://fw_env.config \
    file://rugix-uboot.cfg \
"

# Make `u-boot.inc`'s do_compile step compile boot.cmd into boot.scr (via
# `mkimage -T script`) and deploy it to DEPLOY_DIR_IMAGE, so wic /
# bootimg-partition picks it up via IMAGE_BOOT_FILES.
UBOOT_ENV:imx-nxp-bsp = "boot"
UBOOT_ENV_SUFFIX:imx-nxp-bsp = "scr"
