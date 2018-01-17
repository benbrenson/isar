# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH
# Copyright (C) 2017 Mixed Mode GmbH

inherit fetch patch apt-cache

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


python () {
    s = d.getVar('S', True).rstrip('/')
    extract_dir = d.getVar('EXTRACTDIR', True).rstrip('/')

    if s == extract_dir:
        bb.fatal('\nS equals EXTRACTDIR. Maybe SRC_DIR variable was not set.')
}


OPTS = "--tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y ${APT_EXTRA_OPTS}'"
do_install_depends() {
    cd ${PPS}
    apt-get update
    mk-build-deps ${OPTS} -i -r debian/control
}
addtask do_install_depends after do_patch before do_build
do_install_depends[lockfiles] = "${DPKG_LOCK}"
do_install_depends[stamp-extra-info] = "${MACHINE}.chroot"
do_install_depends[chroot] = "1"
do_install_depends[id] = "${BUILDCHROOT_ID}"


# Build package from sources within chroot
do_build() {
    cd ${PPS}
    dpkg-buildpackage ${DEB_SIGN} -pgpg -sn --host-arch=${DEB_ARCH} -Z${DEB_COMPRESSION}
}
do_build[stamp-extra-info] = "${MACHINE}.chroot"
do_build[chroot] = "1"
do_build[id] = "${BUILDCHROOT_ID}"


do_install() {
    cache_add_package ${ISAR_REPO_LOCAL} ${ISAR_CACHE_LOCAL_PREFIX} ${BUILDROOT}/*.deb
}
addtask do_install after do_build
do_install[lockfiles] = "${DPKG_LOCK}"
do_install[stamp-extra-info] = "${DISTRO}.chroot"
do_install[dirs] += "${DEPLOY_DIR_IMAGE}"


do_clean_cache_pkg() {
    pkgs="$(ls ${BUILDROOT}/*.deb || true)"
    for pkg in $pkgs ; do
        cache_delete_package ${ISAR_REPO_LOCAL} ${ISAR_CACHE_LOCAL_PREFIX} "$(basename $pkg | sed 's/_.*.deb//')"
    done
}
addtask do_clean_cache_pkg before do_clean do_cleanall