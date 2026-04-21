# imx-boot and u-boot-imx both inherit uboot-sign, so with
# UBOOT_SIGN_ENABLE=1 they deploy the same DTB / nodtb symlinks and
# bitbake errors on the shared-area conflict. u-boot-imx is the
# authoritative source; drop the duplicates from imx-boot's DEPLOYDIR.
do_deploy:append() {
    if [ "${UBOOT_SIGN_ENABLE}" = "1" ]; then
        rm -f ${DEPLOYDIR}/${UBOOT_DTB_BINARY} \
              ${DEPLOYDIR}/${UBOOT_DTB_SYMLINK} \
              ${DEPLOYDIR}/${UBOOT_NODTB_SYMLINK} \
              ${DEPLOYDIR}/${UBOOT_NODTB_BINARY}
    fi
}
