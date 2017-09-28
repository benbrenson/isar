# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH
# Copyright (C) 2017 Mixed Mode GmbH

inherit fetch patch

# Add dependency from buildchroot creation
DEPENDS += "buildchroot"
do_unpack[deptask] = "do_install"
do_install[rdeptask] = "do_install"

# Each package should have its own unique build folder, so use
# recipe name as identifier
CHROOT_DIR = "${BUILDCHROOT_DIR}"
BUILDROOT = "${BUILDCHROOT_DIR}/${PP}"
EXTRACTDIR = "${BUILDROOT}"
S = "${BUILDROOT}/${SRC_DIR}"
B = "${BUILDROOT}/${BUILD_DIR}"

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
    DEPS=`perl -ne 'next if /^#/; $p=(s/^Build-Depends:\s*/ / or (/^ / and $p)); s/\s*,\s*|\n|\([^)]+\)/ /mg; print if $p' < debian/control`

    (
        flock 200
        # DEPS can either be DEB_HOST_ARCH when running in cross buildchroot
        # or DISTRO_ARCH when running in buildchroot. Both cases differ when
        # setting DEB_ARCH in cross.bbclass or native.bbclass.
        for dep in $DEPS; do
            apt-get ${APT_EXTRA_OPTS} install -y ${dep}
        done
    )   200>${CHROOT_DEPLOY_DIR_DEB}/lock

    dpkg-buildpackage ${DEB_SIGN} -pgpg -sn --host-arch=${DEB_ARCH} -Z${DEB_COMPRESSION}
}
do_build[stamp-extra-info] = "${MACHINE}.chroot"
do_build[chroot] = "1"
do_build[id] = "${BUILDCHROOT_ID}"


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
addtask do_install after do_pre_install before do_post_install
do_install[stamp-extra-info] = "${DISTRO}.chroot"
do_install[chroot] = "1"
do_install[id] = "${BUILDCHROOT_ID}"
