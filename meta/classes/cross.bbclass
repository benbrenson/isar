# This software is a part of ISAR.
# Copyright (C) 2017 Mixed-Mode GmbH

inherit dpkg-cross

FILESPATH_prepend := "${THISDIR}/${BPN}-${PV}:${THISDIR}/${BPN}-${PV}-${PR}:"
CLASSOVERRIDE = "class-cross"

CROSS_COMPILE="${TARGET_PREFIX}"
CCARCH="${TARGET_ARCH}"
ARCH="${TARGET_ARCH}"