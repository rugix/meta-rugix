# Rugix Yocto Layers

This repository provides the official Yocto layers for integrating
[Rugix Ctrl](https://rugix.org/docs/ctrl) and the optional
[Rugix Admin](https://rugix.org/docs/admin) management interface into a custom,
[Yocto-based](https://www.yoctoproject.org) Linux distribution. Rugix Ctrl is
an open-source tool for deploying robust updates and managing application
workloads and persistent state. It is developed by the
[Rugix](https://rugix.org) project.

Rugix Ctrl provides robust and secure over-the-air (OTA) updates with optional
application and persistent state management:

- **A/B Updates**: Atomic system updates with automatic rollback on failure.
- **Delta Updates**: [Highly-efficient delta updates](https://rugix.org/blog/efficient-delta-updates) minimizing bandwidth.
- **Signature Verification**: Cryptographic verification _before_ installing anything anywhere.
- **State Management**: Flexible state management inspired by container-based architectures.
- **Application Updates**: Atomic deployment and rollback of [application workloads](https://rugix.org/docs/ctrl/application-management/).
- **Vendor-Agnostic**: Compatible with [various fleet management solutions](https://rugix.org/docs/ctrl/integration/fleet-management/) (avoids lock-in).
- **Flexible Boot Flows**: Supports [any bootloader and boot process](https://rugix.org/docs/ctrl/updates/system-updates/boot-flows/).

Rugix Ctrl supports different update strategies (symmetric A/B, asymmetric with recovery, incremental updates) and can be adapted to almost any requirements you may have for robust and secure updates.

For details, check out
[Rugix Ctrl's documentation](https://rugix.org/docs/ctrl) and the
[Yocto integration guide](https://rugix.org/docs/ctrl/integration/build-systems/yocto/).

## Supported Yocto Versions

We only support Yocto LTS releases and maintain a dedicated branch for each (e.g., `wrynose`, `scarthgap`, `kirkstone`). Non-LTS Yocto releases are not officially supported.

This branch targets Yocto Wrynose. The Rugix core layer, QEMU BSP examples, and Raspberry Pi BSP examples are the supported baseline.

This branch carries Rugix Ctrl 1.2.0, 1.3.0, and 1.3.1 recipes. BitBake selects the
latest compatible version unless the distribution pins another one.

## Getting Started

We provide [kas](https://github.com/siemens/kas)-based [examples](./examples/) to help you get started quickly.
Each active example has a matching KAS lockfile next to it. Update a lockfile with `kas lock examples/<example>.yaml` when intentionally moving the branch baseline forward.

## Provided Layers

The layer [`meta-rugix-core`](./meta-rugix-core/) provides everything required
for installing Rugix Ctrl, optionally installing Rugix Admin, and building
Rugix-compatible update bundles.
In addition the following board-specific layers (Rugix BSP layers) are provided:

- [`meta-rugix-qemu-arm64-uboot`](./meta-rugix-qemu-arm64-uboot/): supported BSP layer for QEMU ARM64 with U-Boot-based A/B updates.
- [`meta-rugix-qemu-x86_64-grub`](./meta-rugix-qemu-x86_64-grub/): supported BSP layer for QEMU x86_64 with GRUB EFI-based A/B updates.
- [`meta-rugix-rpi-tryboot`](./meta-rugix-rpi-tryboot/): supported BSP layer for Raspberry Pi with [`tryboot`](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#fail-safe-os-updates-tryboot)-based A/B updates (official A/B update mechanism of Raspberry Pi). This requires Raspberry Pi 4 (CM4, Raspberry Pi 400) or newer. The Wrynose example uses upstream `meta-raspberrypi` from its `master` branch.
- [`meta-rugix-rpi-uboot`](./meta-rugix-rpi-uboot/): supported BSP layer for Raspberry Pi with U-Boot-based A/B updates. This is meant as a reference implementation. For actual field deployments, always use the `tryboot` integration. The Wrynose example uses upstream `meta-raspberrypi` from its `master` branch.

The board-specific layers serve as **examples** for how to integrate Rugix Ctrl with specific boards and boot flows.
Depending on your project and requirements, you may need to adapt those layers or write your own.

## Optional Features

`RUGIX_FEATURES` is a space-separated list of optional image integrations. Set it
in your distribution configuration, `local.conf`, or image recipe. It defaults
to an empty list. A global setting applies to every image, including rescue
and initramfs images. To select the feature for one image instead, use a recipe
override, for example:

```bitbake
RUGIX_FEATURES:pn-core-image-minimal = "apps-docker-compose"
```

| Feature | Installs |
| --- | --- |
| `apps` | Rugix Apps systemd services for restoring app units and recovering interrupted deployments. |
| `apps-docker-compose` | Everything in `apps`, Docker Engine, the Compose plugin, persistent Docker storage, and runtime component metadata. |

Both features require `systemd` in `DISTRO_FEATURES` and Rugix Ctrl 1.3.0 or
newer. For binary or generic apps, enable only `apps`:

```bitbake
RUGIX_FEATURES:append = " apps"
```

### Docker Compose Apps

Both QEMU examples enable Docker Compose Apps through the
`examples/include/apps-docker-compose.yaml` KAS fragment. For example, build
the QEMU x86-64 image with:

```sh
mise run build examples/qemu-x86_64-grub.yaml
```

The fragment adds the Wrynose branch of `meta-virtualization`, selects the
Compose plugin, and enables the required distro features. Include it in other
KAS configurations to enable the same integration.

For an existing Yocto project, add `meta-virtualization` and its dependencies
(`meta-oe`, `meta-python`, `meta-networking`, and `meta-filesystems`) to
`BBLAYERS`, using branches matching your Yocto release. Then configure:

```bitbake
RUGIX_FEATURES:append = " apps-docker-compose"
DISTRO_FEATURES:append = " virtualization seccomp ipv6"
PACKAGECONFIG:append:pn-docker-compose = " docker-plugin"
```

Use systemd as the init manager, as the supplied examples do. Unknown Rugix
features and missing required layers or distro features cause an image parse
error.

The `virtualization` feature enables Docker kernel configuration through
`meta-virtualization` for the examples' `linux-yocto` kernels. With a custom
kernel, enable Docker's required namespaces, cgroups, networking, seccomp, and
overlayfs support in your BSP.

The integration enables Docker and the Apps boot services. It publishes
`runtime.docker` and `runtime.docker-compose` component capabilities after
Docker starts, before interrupted app deployments are recovered. Numeric runtime
versions support version constraints. Development labels such as `dev` are
published as capability values instead. App generations and data use Rugix's
state directory. Docker images, containers, and volumes
persist through `/etc/rugix/state/docker.toml`, which persists
`/var/lib/docker` and `/var/lib/containerd`. These defaults assume Rugix state
management is active and Docker uses its default storage paths. Adapt the state
configuration if you change those paths.

Compose services that should return after a reboot need a restart policy.
For example:

```yaml
services:
  web:
    image: nginx:alpine
    restart: unless-stopped
```

Package and deploy stacks as described in the
[Rugix Apps documentation](https://rugix.org/docs/ctrl/application-management/).
Enabling an Apps feature does not grant app lifecycle permissions through the
privileged daemon. Enable `RUGIX_CTRL_DAEMON_APP_LIFECYCLE` separately if Rugix
Admin should manage apps, as described below.

## Rugix Admin

Add Rugix Admin to an image that already integrates Rugix Ctrl by installing
the `rugix-admin` package:

```bitbake
IMAGE_INSTALL:append = " rugix-admin"
```

The package pulls in `rugix-ctrl-daemon` and a compatible `rugix-ctrl` release.
Both systemd services are enabled automatically. Rugix Admin listens on the
loopback interface by default, and optional privileged operation families
remain disabled until explicitly enabled.

All examples select Rugix Ctrl 1.3.1 and include Rugix Admin and the privileged
operation daemon.

Configure the daemon recipe from your distribution configuration or
`local.conf` with the following Boolean variables:

```bitbake
RUGIX_CTRL_DAEMON_FACTORY_RESET = "true"
RUGIX_CTRL_DAEMON_SYSTEM_COMMIT = "true"
RUGIX_CTRL_DAEMON_SYSTEM_REBOOT = "true"
RUGIX_CTRL_DAEMON_APP_LIFECYCLE = "true"
```

Enable only the operations required by the device. See the
[privileged operation daemon reference](https://rugix.org/docs/ctrl/reference/privileged-daemon/)
for the authoritative policy documentation. The recipe builds Rugix Admin and
its embedded browser interface from a pinned source revision.

## Rugix BSP Layers

A Rugix BSP layer configures the image build for a specific target, defining how the disk is partitioned, how the system boots, and what additional packages are required. A BSP layer typically provides:

- **WKS file** for the disk/partition layout.
- **Rugix configuration** via `system.toml` (boot flow, slots) and `bootstrapping.toml` (first-boot bootstrapping).
- **Slot mapping** defining which WIC partitions correspond to update slots (`RUGIX_SLOTS`).
- **`packagegroup-rugix-bsp`** with additional required packages (bootstrapping tools, system configuration, etc.).
- **Bootloader recipes** for target-specific boot artifacts (e.g., GRUB EFI image, U-Boot boot script).

Not all of these are required. For instance, a BSP that uses an external bootstrapping mechanism can omit the bootstrapping configuration (`bootstrapping.toml`) and the associated packages.

**How it works.** The BSP layer's `layer.conf` sets standard Yocto variables with machine overrides:

```bitbake
WKS_FILE:my-machine ?= "my-target.wks"
WKS_FILE_DEPENDS:append:my-machine = " efi-boot-image"
RUGIX_SLOTS:my-machine ?= "system:2"
IMAGE_INSTALL:append:my-machine = " packagegroup-rugix-bsp"
```

- **`WKS_FILE`** sets the WKS file for the disk layout. Override in `local.conf` to use a custom layout.
- **`WKS_FILE_DEPENDS`** declares build-time dependencies of the WKS file.
- **`RUGIX_SLOTS`** maps slot names to WIC partition numbers (e.g., `"system:2"` or `"boot:2 system:4"`).

**Creating a BSP layer.** To create a Rugix BSP layer for a new board, start from one of the provided BSP layers and adapt it. See the [Rugix documentation](https://rugix.org/docs/ctrl/updates/system-updates/boot-flows/) for the available boot flows and configuration options.

## Testing QEMU Images

The QEMU integration tests require a built image, QEMU, `just`, and `uv`.
The test VM needs access to Docker Hub to pull the test container image.
Before testing an image with Apps enabled, prepare the app bundles inside KAS.
Yocto's native tools depend on paths and libraries in that build environment.

For example, build and test the ARM64 image with:

```sh
git submodule update --init --recursive
just build examples/qemu-arm64-uboot.yaml
just kas shell examples/qemu-arm64-uboot.yaml -c "python3 /repo/tests/prepare_app_bundles.py"
just test-arm64
```

Use `examples/qemu-x86_64-grub.yaml` and `just test-x86_64` for x86-64.
CI prepares these bundles before running the existing QEMU test jobs.

## Community Showcase

- [Nexigon](https://github.com/nexigon) is a device management and remote access solution. Its [`meta-nexigon`](https://github.com/nexigon/meta-nexigon) layers come with an official Rugix integration, enabling seamless system updates through the cloud.
- [Sulka](https://codeberg.org/AltidSec/meta-sulka-distro) is a Yocto Linux distribution with a strong focus on security hardening. Sulka comes with an official Rugix integration using Rugix Ctrl for secure, atomic OTA updates.
- [thin-edge.io](https://github.com/thin-edge) is a lightweight edge agent for IoT devices. Its [`meta-tedge`](https://github.com/thin-edge/meta-tedge) layers come with an official Rugix integration, enabling seamless system updates through the cloud.

## Support

This repository is covered by
[Tier 2: Maintained Integration](https://rugix.org/support-commitment/#tier-maintained-integration)
of the Rugix Support Commitment.

## Licensing

This project is licensed under either [MIT](https://github.com/rugix/rugix/blob/main/LICENSE-MIT) or [Apache 2.0](https://github.com/rugix/rugix/blob/main/LICENSE-APACHE) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this project by you, as defined in the Apache 2.0 license, shall be dual licensed as above, without any additional terms or conditions.

---

Made with ❤️ for OSS by [Silitics](https://www.silitics.com)
