# Root filesystem for target installation
#
# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH
# Copyright (C) 2017      Mixed-Mode GmbH

DESCRIPTION = "Multistrap target filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

inherit debian-image

IMAGE_NAME = "${PN}-${PV}-${MACHINE}-${DISTRO_ARCH}"

IMAGE_PREINSTALL += "apt \
                     dbus"


ROOTFS_EXTRA="100"
