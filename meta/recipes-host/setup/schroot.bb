# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

DESCRIPTION="Recipe for setting up schroot and required configs on the host build machine."

inherit fetch

SRC_URI = "file://01_isar.conf \
           file://fstab \
           file://nssdatabases \
           file://15binfmt \
          "

do_setup_schroot() {
    # Check if schroot is installed
    schroot -V || bbfatal "schroot not installed on the build host system."

    sed -i -e 's|##users##|${USER},root|g' ${WORKDIR}/01_isar.conf
    sed -i -e 's|##BUILDCHROOT##|${BUILDCHROOT_DIR}|g' ${WORKDIR}/01_isar.conf
    sed -i -e 's|##ROOTFS_DIR##|${ROOTFS_DIR}|g' ${WORKDIR}/01_isar.conf
    sed -i -e 's|##CROSS_BUILDCHROOT##|${CROSS_BUILDCHROOT_DIR}|g' ${WORKDIR}/01_isar.conf

    sed -i -e 's|##BUILDCHROOT_ID##|${BUILDCHROOT_ID}|g' ${WORKDIR}/01_isar.conf
    sed -i -e 's|##CROSS_BUILDCHROOT_ID##|${CROSS_BUILDCHROOT_ID}|g' ${WORKDIR}/01_isar.conf
    sed -i -e 's|##ROOTFS_ID##|${ROOTFS_ID}|g' ${WORKDIR}/01_isar.conf

    [ -d "/etc/schroot/chroot.d" ] || bbfatal "Config directory /etc/schroot/chroot.d not available."

    sudo install -m 0644 ${WORKDIR}/01_isar.conf /etc/schroot/chroot.d/01_isar.conf
    sudo install -m 0644 ${WORKDIR}/fstab /etc/schroot/default/fstab
    sudo install -m 0644 ${WORKDIR}/nssdatabases /etc/schroot/default/nssdatabases
    sudo install -m 0755 ${WORKDIR}/15binfmt /etc/schroot/setup.d/15binfmt
}
addtask do_setup_schroot after do_unpack before do_build
do_setup_schroot[dirs] += "${DEPLOY_DIR_DEB}"