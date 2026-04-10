set dotenv-load

export KAS_CONTAINER_ENGINE := env("KAS_CONTAINER_ENGINE", "podman")
export KAS_CONTAINER_IMAGE_DISTRO := "debian-bookworm"
export KAS_WORK_DIR := env("KAS_WORK_DIR", justfile_directory() + "/_kas")
export KAS_BUILD_DIR := env("KAS_BUILD_DIR", justfile_directory() + "/build")
export SSTATE_DIR := env("SSTATE_DIR", justfile_directory() + "/cache/sstate-cache")
export DL_DIR := env("DL_DIR", justfile_directory() + "/cache/downloads")

_uv_run := "uv run --with-editable ./deps/rugix-testkit --with pytest --with pytest-timeout"

_deploy_dir := KAS_BUILD_DIR + "/tmp/deploy/images"

_ssh_opts := "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

[private]
_default:
    @just --list

# Remove all build artifacts.
clean:
    rm -rf "{{KAS_WORK_DIR}}"
    rm -rf "{{KAS_BUILD_DIR}}"

# Run an arbitrary kas-container command.
[positional-arguments]
kas *args:
    mkdir -p "{{KAS_WORK_DIR}}"
    mkdir -p "{{KAS_BUILD_DIR}}"
    kas-container "$@"

# Build a Yocto image with kas-container.
[positional-arguments]
build *args:
    mkdir -p "{{KAS_WORK_DIR}}"
    mkdir -p "{{KAS_BUILD_DIR}}"
    kas-container build "$@"

# Build all QEMU example images.
build-qemu-all:
    @just build examples/qemu-x86_64-grub.yaml
    @just build examples/qemu-arm64-uboot.yaml

# Run the QEMU x86-64 image with GRUB EFI boot.
[positional-arguments]
run-qemu-x86_64 *args:
    {{ _uv_run }} rugix-testkit run --arch x86_64 --ssh-port 2222 \
        --drive {{ _deploy_dir }}/qemux86-64/core-image-minimal-qemux86-64.rootfs.wic,overlay=true,size=16G \
        --pflash {{ _deploy_dir }}/qemux86-64/ovmf.code.qcow2,format=qcow2,readonly=true \
        --pflash {{ _deploy_dir }}/qemux86-64/ovmf.vars.qcow2,format=qcow2 \
        "$@"

# Run the QEMU ARM64 image with U-Boot.
[positional-arguments]
run-qemu-arm64 *args:
    {{ _uv_run }} rugix-testkit run --arch aarch64 --cpu cortex-a57 --ssh-port 2222 \
        --drive {{ _deploy_dir }}/qemuarm64/core-image-minimal-qemuarm64.rootfs.wic,interface=virtio,overlay=true,size=16G \
        --pflash {{ _deploy_dir }}/qemuarm64/u-boot.bin,size=64M,readonly=true \
        --pflash ,size=64M \
        "$@"

# SSH into a running QEMU VM.
ssh-qemu:
    ssh {{ _ssh_opts }} -p 2222 root@localhost

# Copy a file into a running QEMU VM.
scp-qemu file dest="/root":
    scp {{ _ssh_opts }} -P 2222 "{{file}}" "root@localhost:{{dest}}"

# Run all integration tests.
[positional-arguments]
test *args:
    {{ _uv_run }} pytest tests/ "$@"

# Run integration tests for x86-64 only.
[positional-arguments]
test-x86_64 *args:
    {{ _uv_run }} pytest tests/ -k "qemux86-64" "$@"

# Run integration tests for ARM64 only.
[positional-arguments]
test-arm64 *args:
    {{ _uv_run }} pytest tests/ -k "qemuarm64" "$@"