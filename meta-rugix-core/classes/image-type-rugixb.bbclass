# Rugix bundle image type.
#
# Produces a .rugixb update bundle from WIC image partitions. BSP sublayers
# set RUGIX_SLOTS in their layer.conf to map slot names to WIC partition
# numbers (e.g., "system:2" or "boot:2 system:4").

IMAGE_TYPES += "rugixb"
IMAGE_TYPEDEP:rugixb = "wic"

CONVERSIONTYPES += "hash"
CONVERSION_CMD:hash = "rugix-bundler hash ${IMAGE_NAME}.${type} >${IMAGE_NAME}.${type}.hash"
CONVERSION_DEPENDS_hash = "rugix-bundler-native"

RUGIX_SLOTS ??= ""

do_image_rugixb[depends] += "rugix-bundler-native:do_populate_sysroot"

IMAGE_CMD:rugixb () {
    bundle_dir="${WORKDIR}/build-rugixb"
    rm -rf "${bundle_dir}"
    mkdir -p "${bundle_dir}/payloads"

    wic_build_dir="${WORKDIR}/build-wic"

    cat > "${bundle_dir}/rugix-bundle.toml" << 'EOF'
update-type = "full"
hash-algorithm = "sha512-256"
EOF

    payload_idx=1
    for slot_spec in ${RUGIX_SLOTS}; do
        slot_name="${slot_spec%%:*}"
        partition_num="${slot_spec##*:}"

        partition_file=""
        for f in "${wic_build_dir}"/*.direct.p${partition_num}; do
            if [ -f "$f" ]; then
                partition_file="$f"
                break
            fi
        done

        if [ -z "${partition_file}" ]; then
            bbfatal "Partition ${partition_num} not found in WIC build directory for slot ${slot_name}"
        fi

        cp "${partition_file}" "${bundle_dir}/payloads/partition${payload_idx}.img"

        cat >> "${bundle_dir}/rugix-bundle.toml" << SLOTEOF

[[payloads]]
filename = "partition${payload_idx}.img"

[payloads.delivery]
type = "slot"
slot = "${slot_name}"

[payloads.block-encoding]
hash-algorithm = "sha512-256"
chunker = "casync-64"
compression = { type = "xz", level = 9 }
deduplication = true
SLOTEOF

        payload_idx=$(expr ${payload_idx} + 1)
    done

    if [ "${payload_idx}" -eq 1 ]; then
        bbfatal "RUGIX_SLOTS is empty, set it in the BSP layer to define the slot-to-partition mapping."
    fi

    rugix-bundler bundle "${bundle_dir}" "${IMGDEPLOYDIR}/${IMAGE_NAME}.rugixb"
}
