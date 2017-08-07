# This software is a part of ISAR.
# Copyright (C) 2017 Mixed-Mode GmbH

DEPENDS += "cross-buildchroot"

CLASSOVERRIDE = "class-native"

CHROOT_DIR = "${CROSS_BUILDCHROOT_DIR}"
BUILDROOT = "${CHROOT_DIR}/${PP}"
EXTRACTDIR = "${BUILDROOT}"
S = "${EXTRACTDIR}/${SRC_DIR}"

DEB_ARCH = "${DEB_HOST_ARCH}"

# Install package to dedicated deploy directory
do_install() {
    install -d ${DEPLOY_DIR_DEB}/${DEB_HOST_ARCH}
    install -m 755 ${BUILDROOT}/*.deb ${DEPLOY_DIR_DEB}/${DEB_HOST_ARCH}
}


# Set chroot environment for do build task
do_build[id] = "${CROSS_BUILDCHROOT_ID}"





