FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:qemuarm64 = " file://mtd.cfg"
