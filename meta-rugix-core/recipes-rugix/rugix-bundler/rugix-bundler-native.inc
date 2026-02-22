DESCRIPTION = "Native version of Rugix Bundler"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "git://github.com/silitics/rugix.git;branch=main;protocol=https"

S = "${WORKDIR}/git"

inherit cargo native

do_compile[network] = "1"
CARGO_DISABLE_BITBAKE_VENDORING = "1"
CARGO_BUILD_FLAGS:append = " --bin rugix-bundler "
CARGO_BUILD_FLAGS:remove = "--frozen"
CARGO_BUILD_FLAGS:append = " --config 'profile.release.strip="none"'"
