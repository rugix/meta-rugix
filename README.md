# Rugix Yocto Layers

This repository provides Yocto layers for integrating [Rugix Ctrl](https://rugix.org/docs/ctrl) into a custom, [Yocto-based](https://www.yoctoproject.org) Linux distribution tailored to your embedded device.
Rugix Ctrl **enables secure and efficient over-the-air (OTA) updates and provides robust state management capabilities** designed to streamline the development and maintenance of embedded Linux devices at scale.
Rugix Ctrl is part of the [Rugix Project](https://rugix.org).

Rugix Ctrl is a state-of-the-art update and state management engine:

- **A/B Updates**: Atomic system updates with automatic rollback on failure.
- **Delta Updates**: [Highly-efficient delta updates](https://rugix.org/blog/efficient-delta-updates) minimizing bandwidth.
- **Signature Verification**: Cryptographic verification _before_ installing anything anywhere.
- **State Management**: Flexible state management inspired by container-based architectures.
- **Vendor-Agnostic**: Compatible with [various fleet management solutions](https://rugix.org/docs/ctrl/advanced/fleet-management) (avoids lock-in).
- **Flexible Boot Flows**: Supports [any bootloader and boot process](https://rugix.org/docs/ctrl/advanced/boot-flows).

Rugix Ctrl supports different update strategies (symmetric A/B, asymmetric with recovery, incremental updates) and can be adapted to almost any requirements you may have for robust and secure updates.

For details, check out [Rugix Ctrl's documentation](https://rugix.org/docs/ctrl) and the [documentation on the Yocto layers](https://oss.silitics.com/rugix/docs/ctrl/advanced/yocto-integration/).

## Getting Started

We provide [kas](https://github.com/siemens/kas)-based [examples](./examples/) to help you get started quickly.

## Provided Layers

The layer [`meta-rugix-core`](./meta-rugix-core/) provides everything required for installing Rugix Ctrl and building Rugix-compatible update bundles.
In addition the following board-specific layers are provided:

- [`meta-rugix-rpi-tryboot`](./meta-rugix-rpi-tryboot/): BSP layer for building Raspberry Pi images with [`tryboot`](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#fail-safe-os-updates-tryboot) support (official A/B update mechanism of Raspberry Pi). This requires a Raspberry Pi 4 (CM4, Raspberry Pi 400) or newer.
- [`meta-rugix-rpi-uboot`](./meta-rugix-rpi-uboot/): BSP layer for building Raspberry Pi images with U-Boot-based A/B updates. This is primarily meant as a reference implementation for U-Boot. If you have a newer Raspberry Pi model, use the `tryboot` integration.

The board-specific layers serve as **examples** for how to integrate Rugix Ctrl with specific boards.
Depending on your project and requirements, you may need to adapt those layers or write your own.

## ⚖️ Licensing

This project is licensed under either [MIT](https://github.com/silitics/rugix/blob/main/LICENSE-MIT) or [Apache 2.0](https://github.com/silitics/rugix/blob/main/LICENSE-APACHE) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this project by you, as defined in the Apache 2.0 license, shall be dual licensed as above, without any additional terms or conditions.

---

Made with ❤️ for OSS by [Silitics](https://www.silitics.com)
