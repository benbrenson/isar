# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH
# Copyright (C) 2017 Mixed Mode GmbH

inherit fetch

# Add dependency from buildchroot creation
DEPENDS = "buildchroot"
do_unpack[deptask] = "do_build"

# Each package should have its own unique build folder, so use
# recipe name as identifier
CHROOT_DIR = "${BUILDCHROOT_DIR}"
BUILDROOT = "${BUILDCHROOT_DIR}/${PP}"
EXTRACTDIR = "${BUILDROOT}"
S = "${BUILDROOT}/${SRC_DIR}"

CROSS_COMPILE_ENABLED = "false"

python () {
    s = d.getVar('S', True).rstrip('/')
    extract_dir = d.getVar('EXTRACTDIR', True).rstrip('/')

    if s == extract_dir:
        bb.fatal('\nS equals EXTRACTDIR. Maybe SRC_DIR variable was not set.')
}


# Build package from sources within chroot
do_build() {
    cd ${PPS}
    # Get list of dependencies manually. The package is not in apt, so no apt-get
    # build-dep. dpkg-checkbuilddeps output contains version information and isn't
    # directly suitable for apt-get install.
    DEPS=`perl -ne 'next if /^#/; $p=(s/^Build-Depends:\s*/ / or (/^ / and $p)); s/,|\n|\([^)]+\)//mg; print if $p' < debian/control`

    (

        flock 200
        apt-get install -y $DEPS

    )   200>/lock

    dpkg-buildpackage ${DEB_SIGN} -pgpg -sn -Z${DEB_COMPRESSION}
}
do_build[stamp-extra-info] = "${MACHINE}.chroot"
do_build[chroot] = "1"
do_build[id] = "${BUILDCHROOT_ID}"

# Install package to dedicated deploy directory
do_install() {
    install -d ${DEPLOY_DIR_DEB}/${DISTRO_ARCH}
    install -m 755 ${BUILDROOT}/*.deb ${DEPLOY_DIR_DEB}/${DISTRO_ARCH}
}
addtask do_install after do_build
do_install[dirs] += "${DEPLOY_DIR_DEB}/${DISTRO_ARCH}"
do_install[stamp-extra-info] = "${MACHINE}.chroot"