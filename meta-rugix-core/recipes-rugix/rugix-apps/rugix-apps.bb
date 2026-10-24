SUMMARY = "Boot integration for Rugix Apps"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = " \
    file://rugix-apps-restore-units.service \
    file://rugix-apps-recover.service \
"

S = "${UNPACKDIR}"

inherit allarch features_check systemd

REQUIRED_DISTRO_FEATURES = "systemd"

do_compile[noexec] = "1"

do_install() {
    install -D -m 0644 ${UNPACKDIR}/rugix-apps-restore-units.service \
        ${D}${systemd_system_unitdir}/rugix-apps-restore-units.service
    install -D -m 0644 ${UNPACKDIR}/rugix-apps-recover.service \
        ${D}${systemd_system_unitdir}/rugix-apps-recover.service
}

SYSTEMD_SERVICE:${PN} = "rugix-apps-restore-units.service rugix-apps-recover.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

RDEPENDS:${PN} = "rugix-ctrl (>= 1.3.0)"
