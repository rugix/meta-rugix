LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "file://bootstrapping.toml"

RUGIX_SYSTEM_SIZE ?= "4GiB"

do_install:append() {
    install -d ${D}${sysconfdir}/rugix
    sed 's/@@RUGIX_SYSTEM_SIZE@@/${RUGIX_SYSTEM_SIZE}/g' \
        ${WORKDIR}/bootstrapping.toml > ${D}${sysconfdir}/rugix/bootstrapping.toml
    chmod 0644 ${D}${sysconfdir}/rugix/bootstrapping.toml
}
