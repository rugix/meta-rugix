SUMMARY = "Empty bootstrap marker file deployable via IMAGE_BOOT_FILES"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit nopackages deploy

do_compile[noexec] = "1"
do_install[noexec] = "1"
deltask do_populate_sysroot

do_deploy() {
    install -d ${DEPLOYDIR}
    : > ${DEPLOYDIR}/rugix-bootstrap
}

addtask deploy after do_install
