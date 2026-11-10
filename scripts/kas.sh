#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
mkdir -p "$KAS_WORK_DIR" "$KAS_BUILD_DIR" "$KAS_TMP_DIR"
chmod 1777 "$KAS_TMP_DIR"
runtime_args="-v $KAS_TMP_DIR:/tmp:rw"
args=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        --runtime-args)
            runtime_args+=" ${2:?--runtime-args requires a value}"
            shift 2
            ;;
        --runtime-args=*)
            runtime_args+=" ${1#*=}"
            shift
            ;;
        *)
            args+=("$1")
            shift
            ;;
    esac
done
exec kas-container --runtime-args "$runtime_args" "${args[@]}"
