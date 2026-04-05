set dotenv-load

export KAS_CONTAINER_ENGINE := env("KAS_CONTAINER_ENGINE", "podman")
export KAS_WORK_DIR := env("KAS_WORK_DIR", justfile_directory() + "/_kas")
export KAS_BUILD_DIR := env("KAS_BUILD_DIR", justfile_directory() + "/build")
export SSTATE_DIR := env("SSTATE_DIR", justfile_directory() + "/cache/sstate-cache")
export DL_DIR := env("DL_DIR", justfile_directory() + "/cache/downloads")

[private]
_default:
    @just --list

clean:
    rm -rf "{{KAS_WORK_DIR}}"
    rm -rf "{{KAS_BUILD_DIR}}"
    mkdir -p "{{KAS_WORK_DIR}}"
    mkdir -p "{{KAS_BUILD_DIR}}"

[positional-arguments]
kas *args:
    kas-container "$@"

[positional-arguments]
build *args:
    kas-container build "$@"

run-qemu-x86_64 *args:
    @scripts/run-qemu-x86_64 {{args}}

run-qemu-arm64 *args:
    @scripts/run-qemu-arm64 {{args}}

_uv_run := "uv run --with-editable ./deps/rugix-testkit --with pytest --with pytest-timeout"

[positional-arguments]
test *args:
    {{ _uv_run }} pytest tests/ "$@"

[positional-arguments]
test-x86_64 *args:
    {{ _uv_run }} pytest tests/ -k "qemux86-64" "$@"

[positional-arguments]
test-arm64 *args:
    {{ _uv_run }} pytest tests/ -k "qemuarm64" "$@"