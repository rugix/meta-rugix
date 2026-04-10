# NXP's linux-imx recipe inherits kernel-yocto and processes KERNEL_FEATURES,
# but its kernel-metadata search path does NOT include poky's
# meta/recipes-kernel/linux/files/ - so the standard scc feature files
# (e.g. features/overlayfs/overlayfs.scc) that meta-rugix-rpi-uboot relies
# on are not visible. Ship the config option as a plain .cfg fragment
# instead; kernel-yocto picks up .cfg files in SRC_URI automatically.

SRC_URI:append:imx-nxp-bsp = " file://rugix-overlayfs.cfg"
