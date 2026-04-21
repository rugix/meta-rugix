# Rugix U-Boot boot script for NXP i.MX boards with A/B system updates.
#
# Generic across the imx-nxp-bsp machine-override family. Nothing below
# is board-specific - every board-dependent value is resolved from U-Boot
# environment variables that u-boot-imx populates at startup or that
# distroboot sets while scanning for this script:
#
#   ${devnum}       Set by distroboot to the MMC device we booted from
#                   (0 = eMMC, 1 = SD on FRDM-IMX91). Used throughout
#                   so one boot.scr covers both. NXP's u-boot-imx does
#                   not expose `mmc_bootdev`; `devnum` is the only
#                   reliable runtime indicator.
#
#   ${console}      Set by NXP u-boot defconfig (CONFIG_EXTRA_ENV_SETTINGS)
#                   to the right serial console for the board, e.g.
#                   "ttyLP0,115200 earlycon" on FRDM-IMX91. Includes
#                   `earlycon` already - don't add it a second time in
#                   bootargs.
#
# Each A/B slot has its FIT image (kernel, device tree, initramfs) on
# its own FAT partition (boot-a = partition 2, boot-b = partition 3),
# always as a single file named "fitImage". The FAT image is treated as
# an opaque blob at update time (one raw write per slot, atomic at the
# block layer) but lets U-Boot fatload just the FIT at boot time.
# The FIT carries a bootargs property with image-specific parameters
# (e.g. dm-verity root hash); this script reads it from the FIT via
# `fdt get value`, appends slot-specific partition info, and boots.
#
# When UBOOT_SIGN_ENABLE is set at build time, both this boot script
# and the kernel FIT images are signed. U-Boot verifies signatures
# before executing/booting.
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

# Determine which boot group to use. rugix_bootpart stores the boot
# partition of the default group (2=A, 3=B). The system partition is
# boot_part + 2 (4=A, 5=B).
if test "${rugix_boot_spare}" = "1"; then
  if test "${rugix_bootpart}" = "3"; then
    setenv rugix_boot_part 2
  else
    setenv rugix_boot_part 3
  fi
  setenv rugix_boot_spare 0
  setenv rugix_state_dirty 1
else
  if test "${rugix_bootpart}" = "3"; then
    setenv rugix_boot_part 3
  else
    setenv rugix_boot_part 2
  fi
fi

# Derive system partition and boot group name from boot partition.
setexpr rugix_sys_part ${rugix_boot_part} + 2
if test "${rugix_boot_part}" = "2"; then
  setenv rugix_boot_group a
else
  setenv rugix_boot_group b
fi

echo "Boot group: ${rugix_boot_group} (boot=${rugix_boot_part} system=${rugix_sys_part})"

# Persist only when state actually changed.
if test -n "${rugix_state_dirty}"; then
  env export -c -s 0x4000 ${loadaddr} rugix_bootpart rugix_boot_spare
  fatwrite mmc ${devnum}:1 ${loadaddr} rugix.env 0x4000
fi

# Load the FIT from the boot partition to a staging address so bootm
# can extract the kernel without overwriting the FIT blob. The boot
# partition is a FAT image wrapping the FIT file, so only the FIT is
# read into memory (not the whole partition).
setexpr fit_addr ${loadaddr} + 0x8000000

echo "Loading FIT from partition ${rugix_boot_part}..."
fatload mmc ${devnum}:${rugix_boot_part} ${fit_addr} fitImage

# Extract bootargs baked into the FIT by the build system. These are
# image-specific and slot-agnostic (e.g. dm-verity root hash).
fdt addr ${fit_addr}
fdt get value fit_bootargs / bootargs

# Resolve the system partition's PARTUUID.
part uuid mmc ${devnum}:${rugix_sys_part} rugix_root_uuid

# Combine FIT bootargs with slot-specific parameters. Verification of
# ${fit_bootargs} happens as part of bootm. If the FIT image has been
# manipulated, bootm won't boot it regardless of what we set here.
setenv bootargs ${fit_bootargs} root=PARTUUID=${rugix_root_uuid} rugix.boot_group=${rugix_boot_group} rootwait init=/usr/bin/rugix-ctrl ro console=${console} panic=60

# Boot kernel + initramfs from the FIT.
bootm ${fit_addr}
