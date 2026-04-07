# Rugix BSP integration for image recipes.
#
# BSP sublayers set RUGIX_WKS_FILE, RUGIX_WKS_FILE_DEPENDS, and RUGIX_SLOTS
# in their layer.conf (guarded by the MACHINE). Override RUGIX_WKS_FILE in
# local.conf to use a custom WKS file.

RUGIX_WKS_FILE ??= ""
RUGIX_WKS_FILE_DEPENDS ??= ""

python() {
    if not bb.utils.contains('DISTRO_FEATURES', 'rugix', True, False, d):
        return
    wks_file = d.getVar('RUGIX_WKS_FILE')
    if not wks_file:
        return
    d.setVar('WKS_FILE', wks_file)
    wks_depends = d.getVar('RUGIX_WKS_FILE_DEPENDS')
    if wks_depends:
        d.appendVar('WKS_FILE_DEPENDS', ' ' + wks_depends)
    d.appendVar('IMAGE_INSTALL', ' packagegroup-rugix-bsp')
}
