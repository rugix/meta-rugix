SUMMARY = "Rugix A/B boot script as a FIT image"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "u-boot-tools-native dtc-native"

SRC_URI = "file://boot.cmd"

inherit deploy nopackages

RUGIX_BOOTSCRIPT_SIGN_ALGO ??= "sha256,rsa2048"

do_compile() {
    cp ${WORKDIR}/boot.cmd ${B}/boot.cmd

    signature_block=""
    if [ "${UBOOT_SIGN_ENABLE}" = "1" ]; then
        signature_block=$(cat <<EOF

            signature {
                algo = "${RUGIX_BOOTSCRIPT_SIGN_ALGO}";
                key-name-hint = "${UBOOT_SIGN_KEYNAME}";
                sign-images = "script";
            };
EOF
)
    fi

    cat > ${B}/boot-script.its <<EOF
/dts-v1/;

/ {
    description = "Rugix A/B Boot Script";
    #address-cells = <1>;

    images {
        bootscr-1 {
            description = "A/B boot script";
            type = "script";
            compression = "none";
            data = /incbin/("boot.cmd");
            hash-1 { algo = "sha256"; };
        };
    };

    configurations {
        default = "conf-1";
        conf-1 {
            description = "Boot Script";
            script = "bootscr-1";${signature_block}
        };
    };
};
EOF

    uboot-mkimage -f ${B}/boot-script.its ${B}/boot.scr
}

do_compile:append() {
    if [ "${UBOOT_SIGN_ENABLE}" = "1" ]; then
        if [ ! -f "${UBOOT_SIGN_KEYDIR}/${UBOOT_SIGN_KEYNAME}.key" ]; then
            bbfatal "UBOOT_SIGN_ENABLE=1 but ${UBOOT_SIGN_KEYNAME}.key not found in UBOOT_SIGN_KEYDIR=${UBOOT_SIGN_KEYDIR}. Run 'just gen-signing-keys' to create one."
        fi
        uboot-mkimage -F \
            -k "${UBOOT_SIGN_KEYDIR}" \
            -r ${B}/boot.scr
    fi
}

do_deploy() {
    install -m 0644 ${B}/boot.scr ${DEPLOYDIR}/boot.scr
}

addtask deploy after do_compile before do_build
