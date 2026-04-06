# Rugix Yocto Layers

This repository provides Yocto layers for integrating [Rugix Ctrl](https://rugix.org/docs/ctrl) into a custom, [Yocto-based](https://www.yoctoproject.org) Linux distribution tailored to your embedded device.
Rugix Ctrl **enables secure and efficient over-the-air (OTA) updates and provides robust state management capabilities** designed to streamline the development and maintenance of embedded Linux devices at scale.
Rugix Ctrl is part of the [Rugix Project](https://rugix.org).

Rugix Ctrl is a state-of-the-art update and state management engine:

- **A/B Updates**: Atomic system updates with automatic rollback on failure.
- **Delta Updates**: [Highly-efficient delta updates](https://rugix.org/blog/efficient-delta-updates) minimizing bandwidth.
- **Signature Verification**: Cryptographic verification _before_ installing anything anywhere.
- **State Management**: Flexible state management inspired by container-based architectures.
- **Application Updates**: Atomic deployment and rollback of [application workloads](https://rugix.org/docs/ctrl/application-updates/).
- **Vendor-Agnostic**: Compatible with [various fleet management solutions](https://rugix.org/docs/ctrl/advanced/fleet-management) (avoids lock-in).
- **Flexible Boot Flows**: Supports [any bootloader and boot process](https://rugix.org/docs/ctrl/advanced/boot-flows).

Rugix Ctrl supports different update strategies (symmetric A/B, asymmetric with recovery, incremental updates) and can be adapted to almost any requirements you may have for robust and secure updates.

For details, check out [Rugix Ctrl's documentation](https://rugix.org/docs/ctrl) and the [documentation on the Yocto layers](https://rugix.org/docs/ctrl/advanced/yocto-integration/).

## Supported Yocto Versions

We only support Yocto LTS releases and maintain a dedicated branch for each (e.g., `scarthgap`, `kirkstone`). The `main` branch tracks the latest supported LTS release. Non-LTS Yocto releases are not officially supported.

## Getting Started

We provide [kas](https://github.com/siemens/kas)-based [examples](./examples/) to help you get started quickly.

## Provided Layers

The layer [`meta-rugix-core`](./meta-rugix-core/) provides everything required for installing Rugix Ctrl and building Rugix-compatible update bundles.
In addition the following board-specific layers (Rugix BSP layers) are provided:

- [`meta-rugix-rpi-tryboot`](./meta-rugix-rpi-tryboot/): BSP layer for Raspberry Pi with [`tryboot`](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#fail-safe-os-updates-tryboot)-based A/B updates (official A/B update mechanism of Raspberry Pi). This requires Raspberry Pi 4 (CM4, Raspberry Pi 400) or newer.
- [`meta-rugix-rpi-uboot`](./meta-rugix-rpi-uboot/): BSP layer for Raspberry Pi with U-Boot-based A/B updates. This is meant as a reference implementation. For actual field deployments, always use the `tryboot` integration.
- [`meta-rugix-qemu-arm64-uboot`](./meta-rugix-qemu-arm64-uboot/): BSP layer for QEMU ARM64 with U-Boot-based A/B updates.
- [`meta-rugix-qemu-x86_64-grub`](./meta-rugix-qemu-x86_64-grub/): BSP layer for QEMU x86_64 with GRUB EFI-based A/B updates.

The board-specific layers serve as **examples** for how to integrate Rugix Ctrl with specific boards and boot flows.
Depending on your project and requirements, you may need to adapt those layers or write your own.

## Rugix BSP Layers

A Rugix BSP layer configures the image build for a specific target, defining how the disk is partitioned, how the system boots, what packages are required, and what build artifacts are produced. All integration is driven by the `rugix` distro feature. When enabled, the core classes apply the BSP configuration to every image automatically.

A BSP layer typically provides:

- **WKS file** for the disk/partition layout.
- **Boot configuration** via `system.toml` (boot flow, slots) and `bootstrapping.toml` (first-boot bootstrapping).
- **Slot mapping** defining which WIC partitions are update slots (`RUGIX_SLOTS`).
- **`packagegroup-rugix-bsp`** with the target packages (bootstrapping tools, system configuration, etc.).
- **Bootloader recipes** for target-specific boot artifacts (e.g., GRUB EFI image, U-Boot boot script).

Not all of these are required. A BSP that does not use A/B updates can omit `RUGIX_SLOTS` and the slot-related configuration, and no update bundles will be produced. Similarly, a BSP that uses an external bootstrapping mechanism can omit `bootstrapping.toml` and the associated packages.

**How it works.** The BSP layer's `layer.conf` registers itself with the core infrastructure:

```bitbake
IMAGE_CLASSES += "rugix-bsp"
RUGIX_WKS_FILE ?= "my-target.wks"
RUGIX_WKS_FILE_DEPENDS ?= "efi-boot-image"
RUGIX_SLOTS ?= "system:2"
```

- **`RUGIX_WKS_FILE`** sets the WKS file for the disk layout. Override in `local.conf` to use a custom layout.
- **`RUGIX_WKS_FILE_DEPENDS`** declares build-time dependencies of the WKS file.
- **`RUGIX_SLOTS`** maps slot names to WIC partition numbers (e.g., `"system:2"` or `"boot:2 system:4"`). When non-empty, the `rugixb` image type is automatically added to `IMAGE_FSTYPES` and a `.rugixb` update bundle is produced alongside the `.wic` image. Leave empty to disable automatic bundle creation.

**Creating a BSP layer.** To create a Rugix BSP layer for a new board, start from one of the provided BSP layers and adapt it. The `layer.conf` must depend on `meta-rugix-core`, add `rugix-bsp` to `IMAGE_CLASSES`, and set the BSP variables. The layer provides a WKS file, a `packagegroup-rugix-bsp`, and bbappends for `rugix-system-conf` and `rugix-bootstrapping-conf` with board-specific TOML configuration. See the [Rugix documentation](https://rugix.org/docs/ctrl/advanced/boot-flows) for the available boot flows and configuration options.

## Licensing

This project is licensed under either [MIT](https://github.com/rugix/rugix/blob/main/LICENSE-MIT) or [Apache 2.0](https://github.com/rugix/rugix/blob/main/LICENSE-APACHE) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this project by you, as defined in the Apache 2.0 license, shall be dual licensed as above, without any additional terms or conditions.

---

Made with ❤️ for OSS by [Silitics](https://www.silitics.com)
