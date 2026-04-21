FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:imx-nxp-bsp = " \
    file://fw_env.config \
    file://rugix-uboot.cfg \
    ${@bb.utils.contains('UBOOT_SIGN_ENABLE', '1', 'file://rugix-uboot-fit-verify.cfg', '', d)} \
"
