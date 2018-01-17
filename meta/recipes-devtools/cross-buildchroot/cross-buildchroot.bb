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
ROOT_DIR = "${CROSS_BUILDCHROOT_DIR}"
CHROOT_ID = "${CROSS_BUILDCHROOT_ID}"
ARCH = "${DEB_HOST_ARCH}"
INSTALL = "${BUILDCHROOT_PREINSTALL}"

# Some packages are only installable after late configurations for
# apt
BUILDCHROOT_POSTINSTALL = "crossbuild-essential-${DISTRO_ARCH} devscripts"


# Run late cross-buildchroot specific configurations on rootfs
do_setup_rootfs_append() {
    # Create packages build folder
    sudo install -m 0777 -d ${ROOT_DIR}/home/builder
}


do_configure_rootfs_prepend() {
    rm -f /${sysconfdir}/dpkg/dpkg.cfg.d/multiarch

    # Configure root filesystem for cross compiling
    # multistraps multiarch setting is not working
    dpkg --add-architecture ${DISTRO_ARCH}
    echo "Acquire::AllowInsecureRepositories \"true\";" > /${sysconfdir}/apt/apt.conf.d/10allowunauth
}


do_configure_rootfs_append() {
    apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" ${BUILDCHROOT_POSTINSTALL}

    # Remove [arch=<host_arch>] from apt sources file
    # This will enable multiarch support
	sed -i 's|arch=${DEB_HOST_ARCH}||g' \
		/${sysconfdir}/apt/sources.list.d/multistrap-*.list
    apt-get update
}
