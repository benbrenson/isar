# This software is a part of ISAR.
# Copyright (C) 2017 Mixed-Mode GmbH

DEPENDS += "cross-buildchroot"

OVERRIDES .= ":class-native"

CHROOT_DIR = "${CROSS_BUILDCHROOT_DIR}"
BUILDROOT = "${CHROOT_DIR}/${PP}"
EXTRACTDIR = "${BUILDROOT}"
S = "${EXTRACTDIR}/${SRC_DIR}"

DEB_ARCH = "${DEB_HOST_ARCH}"


# Set chroot environment for do build and do_install task
do_build[id] = "${CROSS_BUILDCHROOT_ID}"
do_install[id] = "${CROSS_BUILDCHROOT_ID}"





