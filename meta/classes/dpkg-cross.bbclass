# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

# Class implementing common functionalities for running cross builds
# for debianized packages.
# Do not directly inherit this class.
# Instead inherit from cross.bbclass, which is done by setting the BBCLASSEXTEND = "cross" within your recipe.

inherit fetch patch apt-cache

DEPENDS += "cross-buildchroot"
do_unpack[deptask] = "do_install"
do_install[rdeptask] = "do_install"

CHROOT_DIR = "${CROSS_BUILDCHROOT_DIR}"
BUILDROOT = "${CHROOT_DIR}/${PP}"
EXTRACTDIR = "${BUILDROOT}"
S = "${EXTRACTDIR}/${SRC_DIR}"
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
do_install_depends[id] = "${CROSS_BUILDCHROOT_ID}"


# Build package from sources
do_build() {
    cd ${PPS}
    dpkg-buildpackage ${DEB_SIGN} -pgpg -sn --host-arch=${DEB_ARCH} -Z${DEB_COMPRESSION}
}
do_build[stamp-extra-info] = "${MACHINE}.chroot"
do_build[chroot] = "1"
do_build[id] = "${CROSS_BUILDCHROOT_ID}"


do_install() {
    cache_add_package ${ISAR_REPO_LOCAL} ${ISAR_CACHE_LOCAL_PREFIX} ${BUILDROOT}/*.deb
}
addtask do_install after do_build
do_install[lockfiles] = "${DPKG_LOCK}"
do_install[stamp-extra-info] = "${DISTRO}"
do_install[dirs] += "${DEPLOY_DIR_IMAGE}"


do_clean_cache_pkg() {
    pkgs="$(ls ${BUILDROOT}/*.deb || true)"
    for pkg in $pkgs ; do
        cache_delete_package ${ISAR_REPO_LOCAL} ${ISAR_CACHE_LOCAL_PREFIX} "$(basename $pkg | sed 's/_.*.deb//')"
    done
}
addtask do_clean_cache_pkg before do_clean do_cleanall
