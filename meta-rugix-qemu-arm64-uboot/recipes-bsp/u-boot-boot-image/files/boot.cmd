# Rugix U-Boot boot script for QEMU ARM64 with A/B system updates.
#
# Boot state is managed via U-Boot environment variables stored in flash.

echo "Starting boot..."

# Scan virtio devices.
virtio scan

# Default boot state. Initialize and persist on first boot.
if test -z "${rugix_bootpart}"; then
  setenv rugix_boot_spare 0
  setenv rugix_bootpart 2
  saveenv
fi

echo "Boot Spare: " ${rugix_boot_spare}
echo "Bootpart: " ${rugix_bootpart}

# Determine which system partition to boot.
if test "${rugix_boot_spare}" = "1"; then
  if test "${rugix_bootpart}" = "3"; then
    setenv rugix_boot_dev "virtio 0:2"
    setenv rugix_root "/dev/vda2"
  else
    setenv rugix_boot_dev "virtio 0:3"
    setenv rugix_root "/dev/vda3"
  fi
  setenv rugix_boot_spare 0
  saveenv
else
  if test "${rugix_bootpart}" = "3"; then
    setenv rugix_boot_dev "virtio 0:3"
    setenv rugix_root "/dev/vda3"
  else
    setenv rugix_boot_dev "virtio 0:2"
    setenv rugix_root "/dev/vda2"
  fi
fi

echo "Bootdev: " ${rugix_boot_dev}

# Set kernel command line.
setenv bootargs "root=${rugix_root} init=/usr/bin/rugix-ctrl ro console=ttyAMA0,115200 panic=60"

# Load and boot kernel from the selected system partition.
load ${rugix_boot_dev} ${kernel_addr_r} boot/Image
booti ${kernel_addr_r} - ${fdt_addr}
