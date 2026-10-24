SUMMARY = "Docker Compose integration for Rugix Apps"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = " \
    file://docker.toml \
    file://rugix-docker-runtime-components \
    file://rugix-docker-runtime-components.service \
    file://docker-compose.conf \
"

S = "${UNPACKDIR}"

inherit allarch features_check systemd

REQUIRED_DISTRO_FEATURES = "systemd virtualization seccomp ipv6"

do_compile[noexec] = "1"

do_install() {
    install -D -m 0644 ${UNPACKDIR}/docker.toml \
        ${D}${sysconfdir}/rugix/state/docker.toml
    install -D -m 0755 ${UNPACKDIR}/rugix-docker-runtime-components \
        ${D}${libexecdir}/rugix/rugix-docker-runtime-components
    sed 's|@LIBEXECDIR@|${libexecdir}|g' \
        ${UNPACKDIR}/rugix-docker-runtime-components.service > ${WORKDIR}/rugix-docker-runtime-components.service
    install -D -m 0644 ${WORKDIR}/rugix-docker-runtime-components.service \
        ${D}${systemd_system_unitdir}/rugix-docker-runtime-components.service
    install -D -m 0644 ${UNPACKDIR}/docker-compose.conf \
        ${D}${systemd_system_unitdir}/rugix-apps-recover.service.d/docker-compose.conf
}

SYSTEMD_SERVICE:${PN} = "rugix-docker-runtime-components.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

CONFFILES:${PN} = "${sysconfdir}/rugix/state/docker.toml"
FILES:${PN} += "${systemd_system_unitdir}/rugix-apps-recover.service.d"
RDEPENDS:${PN} = "rugix-apps docker-moby docker-moby-cli docker-compose"
