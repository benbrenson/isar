# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

# Class implementing common functionalities for running cross builds
# for debianized packages.
# Do not directly inherit this class.
# Instead inherit from cross.bbclass.

inherit fetch

DEPENDS += "buildchroot cross-buildchroot"
do_unpack[deptask] = "do_install"
do_install[rdeptask] = "do_install"

CHROOT_DIR = "${CROSS_BUILDCHROOT_DIR}"
BUILDROOT = "${CHROOT_DIR}/${PP}"
EXTRACTDIR = "${BUILDROOT}"
S = "${EXTRACTDIR}/${SRC_DIR}"
B = "${BUILDROOT}/${BUILD_DIR}"

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
    DEPS=`perl -ne 'next if /^#/; $p=(s/^Build-Depends:\s*/ / or (/^ / and $p)); s/\s*,\s*|\n|\([^)]+\)/ /mg; print if $p' < debian/control`

    (
        flock 200
        for dep in $DEPS; do
            apt-get ${APT_EXTRA_OPTS} install -y ${dep}
        done
    )   200>${CHROOT_DEPLOY_DIR_DEB}/lock

    dpkg-buildpackage ${DEB_SIGN} -pgpg -sn --host-arch=${DEB_ARCH} -Z${DEB_COMPRESSION}
}
do_build[stamp-extra-info] = "${MACHINE}.chroot"
do_build[chroot] = "1"
do_build[id] = "${CROSS_BUILDCHROOT_ID}"



# Install package to dedicated deploy directory
do_pre_install() {
    install -d ${DEPLOY_DIR_DEB}/${DEB_ARCH}
    install -m 755 ${BUILDROOT}/*.deb ${DEPLOY_DIR_DEB}/${DEB_ARCH}
}
addtask do_pre_install after do_build before do_install
do_pre_install[stamp-extra-info] = "${DISTRO}"
do_pre_install[dirs] += "${DEPLOY_DIR_IMAGE}"

# Update the local apt cache
do_install() {
    (
        flock 200
        # Need to cd into directory, since index is relative
        cd ${CHROOT_DEPLOY_DIR_DEB}/${DEB_ARCH}
        # gzip is not required for local repos
        dpkg-scanpackages ./ > ${CHROOT_DEPLOY_DIR_DEB}/${DEB_ARCH}/Packages
        apt-get update
    )   200>${CHROOT_DEPLOY_DIR_DEB}/lock
}
addtask do_install after do_build
do_install[prefuncs] = "do_pre_install"
do_install[stamp-extra-info] = "${DISTRO}"
do_install[chroot] = "1"
do_install[id] = "${CROSS_BUILDCHROOT_ID}"