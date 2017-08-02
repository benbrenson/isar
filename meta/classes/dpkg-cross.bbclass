# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

# Class implementing common functionalities for running cross builds
# for debianized packages

inherit fetch

DEPENDS += "buildchroot cross-buildchroot"
do_unpack[deptask] = "do_build"

CROSS_COMPILE="arm-linux-gnueabihf-"
CCARCH="${TARGET_ARCH}"
ARCH="${TARGET_ARCH}"

CHROOT_DIR = "${CROSS_BUILDCHROOT_DIR}"
BUILDROOT = "${CHROOT_DIR}/${PP}"
EXTRACTDIR = "${BUILDROOT}"
S = "${EXTRACTDIR}/${SRC_DIR}"

CROSS_COMPILE_ENABLED = "true"

python () {
    s = d.getVar('S', True).rstrip('/')
    extract_dir = d.getVar('EXTRACTDIR', True).rstrip('/')

    if s == extract_dir:
        bb.fatal('\nS equals EXTRACTDIR. Maybe SRC_DIR variable was not set.')
}

# Build package from sources
do_build() {
    cd ${PPS}
    # Get list of dependencies manually. The package is not in apt, so no apt-get
    # build-dep. dpkg-checkbuilddeps output contains version information and isn't
    # directly suitable for apt-get install.
    DEPS=`perl -ne 'next if /^#/; $p=(s/^Build-Depends:\s*/ / or (/^ / and $p)); s/,|\n|\([^)]+\)//mg; print if $p' < debian/control`
    apt-get install -y $DEPS
    dpkg-buildpackage ${DEB_SIGN} -pgpg -sn --host-arch=${DEB_ARCH} -Z${DEB_COMPRESSION}
}
do_build[stamp-extra-info] = "${MACHINE}.chroot"
do_build[chroot] = "1"
do_build[id] = "${CROSS_BUILDCHROOT_ID}"



# Install package to dedicated deploy directory
do_install() {
    install -m 755 ${BUILDROOT}/*.deb ${DEPLOY_DIR_DEB}/
}
addtask do_install after do_build
do_install[dirs]="${DEPLOY_DIR_DEB}"
do_install[stamp-extra-info] = "${DISTRO}"
