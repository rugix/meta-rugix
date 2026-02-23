#
# Copyright: Esa Jaaskela (ejaaskel)
#
# SPDX-License-Identifier: MIT
#

import logging
from wic.pluginbase import SourcePlugin, PluginMgr
from wic.misc import exec_cmd

logger = logging.getLogger('wic')


class RpiUbootPlugin(SourcePlugin):
    # This rpi-uboot plug-in is an extension to the bootimg-partition plug-in, with the
    # added capability of inserting .rugix/bootstrap marker file. The mkdosfs command
    # that typically generates the boot partition in the bootimg-partition plug-in does
    # not handle hidden files (i.e. files beginning with dot) in the root of the partition
    # properly, so we manually have to create the file after the partition has been
    # created.
    name = "rpi-uboot"

    @classmethod
    def do_configure_partition(cls, part, source_params, cr, cr_workdir,
                               oe_builddir, bootimg_dir, kernel_dir,
                               native_sysroot):
        # bootimg-partition plugin cannot be directly inherited, so we have to
        # get the plugin and call the configuration function manually
        BootimgPartitionPlugin = PluginMgr.get_plugins(
            'source').get('bootimg-partition')

        BootimgPartitionPlugin.do_configure_partition(
            part,
            source_params,
            cr,
            cr_workdir,
            oe_builddir,
            bootimg_dir,
            kernel_dir,
            native_sysroot)

        hdddir = f"{cr_workdir}/boot.{part.lineno}"
        exec_cmd(f"install -d {hdddir}")
        exec_cmd(f"install -d {hdddir}/.rugix")
        exec_cmd(f"touch {hdddir}/.rugix/bootstrap")

    @classmethod
    def do_prepare_partition(cls, part, source_params, cr, cr_workdir,
                             oe_builddir, bootimg_dir, kernel_dir,
                             rootfs_dir, native_sysroot):
        BootimgPartitionPlugin = PluginMgr.get_plugins(
            'source').get('bootimg-partition')

        BootimgPartitionPlugin.do_prepare_partition(
            part,
            source_params,
            cr,
            cr_workdir,
            oe_builddir,
            bootimg_dir,
            kernel_dir,
            rootfs_dir,
            native_sysroot)

        hdddir = f"{cr_workdir}/boot.{part.lineno}"
        rootfs = "%s/rootfs_%s.%s.%s" % (
            cr_workdir,
            part.label,
            part.lineno,
            part.fstype,
        )
        exec_cmd(f"mcopy -i {rootfs} -o -s {hdddir}/.rugix ::/.rugix")
