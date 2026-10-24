SUMMARY = "Rugix Apps with Docker Compose"
LICENSE = "MIT"

inherit packagegroup features_check

REQUIRED_DISTRO_FEATURES = "systemd virtualization seccomp ipv6"

RDEPENDS:${PN} = "rugix-apps-docker-compose docker-moby docker-moby-cli docker-compose"
