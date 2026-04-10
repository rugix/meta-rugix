# Rugix U-Boot boot script for NXP i.MX boards with A/B system updates.
#
# Generic across the imx-nxp-bsp machine-override family. Nothing below
# is board-specific - every board-dependent value is resolved from U-Boot
# environment variables that u-boot-imx populates at startup or that
# distroboot sets while scanning for this script:
#
#   ${devnum}       Set by distroboot's bootcmd_mmc0 / bootcmd_mmc1 loop
#                   before `source`ing this script - identifies the MMC
#                   device distroboot found us on (0 = USDHC1 eMMC,
#                   1 = USDHC2 SD on FRDM-IMX91). NXP's u-boot-imx does
#                   NOT expose the `mmc_bootdev` variable some other
#                   vendors provide; `devnum` is the authoritative
#                   runtime-current-device indicator inside distroboot.
#                   Used for every `mmc` / `load` / `fatwrite` command,
#                   so one boot.scr works for SD or eMMC boot without
#                   a rebuild.
#
#   ${console}      Set by NXP u-boot defconfig (CONFIG_EXTRA_ENV_SETTINGS)
#                   to the right serial console for the board, e.g.
#                   "ttyLP0,115200 earlycon" on FRDM-IMX91. Includes
#                   `earlycon` already - don't add it a second time in
#                   bootargs.
#
#   ${fdtfile}      Set by NXP u-boot defconfig (CONFIG_DEFAULT_FDT_FILE)
#                   to the board's device-tree blob filename, e.g.
#                   "imx91-11x11-frdm.dtb". Looked up in /boot of the
#                   selected system partition.
#
# State (rugix_bootpart, rugix_boot_spare) lives in a binary U-Boot env
# file (rugix.env) on the FAT boot partition. We import it at the start
# of the script and export+fatwrite it whenever state changes. Userspace
# `fw_printenv` / `fw_setenv` read the same file via /etc/fw_env.config,
# so rugix-ctrl needs no special cooperation.

echo "Starting boot..."

mmc dev ${devnum}
mmc rescan

# Load persisted A/B state from the boot partition. If the file does not
# exist yet (first boot), mark the state dirty so we write defaults.
if load mmc ${devnum}:1 ${loadaddr} rugix.env; then
  env import -c ${loadaddr} ${filesize}
else
  setenv rugix_state_dirty 1
fi

# First-boot defaults (rugix.env did not exist yet, or did not carry
# rugix_bootpart for some reason). Either way the state needs to be
# written out.
if test -z "${rugix_bootpart}"; then
  setenv rugix_boot_spare 0
  setenv rugix_bootpart 2
  setenv rugix_state_dirty 1
fi

echo "Boot Spare: " ${rugix_boot_spare}
echo "Bootpart: " ${rugix_bootpart}

# Determine which system partition to boot.
if test "${rugix_boot_spare}" = "1"; then
  if test "${rugix_bootpart}" = "3"; then
    setenv rugix_boot_part 2
  else
    setenv rugix_boot_part 3
  fi
  # Clear the spare flag so the next boot returns to the normal slot.
  # This is a real state transition and must be persisted.
  setenv rugix_boot_spare 0
  setenv rugix_state_dirty 1
else
  if test "${rugix_bootpart}" = "3"; then
    setenv rugix_boot_part 3
  else
    setenv rugix_boot_part 2
  fi
fi

echo "Bootdev: mmc ${devnum}:" ${rugix_boot_part}

# Persist only when state actually changed. `env export -c` requires an
# explicit buffer size; 0x4000 matches CONFIG_ENV_SIZE and fw_env.config.
# rugix_state_dirty itself is not exported - only rugix_bootpart and
# rugix_boot_spare land in the file - and since CONFIG_ENV_IS_NOWHERE=y
# there is no persistent U-Boot env, so the flag starts unset on every
# boot and only trips when one of the branches above sets it.
if test -n "${rugix_state_dirty}"; then
  env export -c -s 0x4000 ${loadaddr} rugix_bootpart rugix_boot_spare
  fatwrite mmc ${devnum}:1 ${loadaddr} rugix.env 0x4000
fi

# Resolve the system partition's PARTUUID so root= does not depend on
# whether Linux enumerates us as mmcblk0 or mmcblk1.
part uuid mmc ${devnum}:${rugix_boot_part} rugix_root_uuid

setenv bootargs "root=PARTUUID=${rugix_root_uuid} rootwait init=/usr/bin/rugix-ctrl ro console=${console} panic=60"

# Load kernel and device tree from the selected system partition's /boot.
load mmc ${devnum}:${rugix_boot_part} ${kernel_addr_r} boot/Image
load mmc ${devnum}:${rugix_boot_part} ${fdt_addr_r} boot/${fdtfile}

booti ${kernel_addr_r} - ${fdt_addr_r}
