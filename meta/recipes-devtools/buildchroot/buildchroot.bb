# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

# Root filesystem for packages building
DESCRIPTION = "Multistrap development filesystem"

inherit rootfs

DEPENDS += "schroot apt-cache"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

WORKDIR = "${TMPDIR}/work/${PF}/${DISTRO}"
ROOT_DIR = "${BUILDCHROOT_DIR}"
CHROOT_ID = "${BUILDCHROOT_ID}"
ARCH = "${DISTRO_ARCH}"
INSTALL = "${BUILDCHROOT_PREINSTALL}"


# Run late buildchroot specific configurations on rootfs
do_setup_rootfs_append() {
	# Create packages build folder
    sudo install -m 0777 -d ${ROOT_DIR}/home/builder
}
