SUMMARY = "Initramfs module that sets up a dm-verity root filesystem"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS:${PN} = "initramfs-framework-base cryptsetup"

SRC_URI = "file://verity"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit allarch

do_install() {
    install -d ${D}/init.d
    install -m 0755 ${WORKDIR}/verity ${D}/init.d/85-verity
}

FILES:${PN} = "/init.d/85-verity"
