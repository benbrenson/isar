# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

DESCRIPTION="Recipe for setting up schroot and required configs on the host build machine."

inherit fetch

SRC_URI = "file://01_isar.conf"

do_setup_schroot() {
    # Check if schroot is installed
    schroot -V

    sed -i -e 's|##users##|${USER},root|g' ${WORKDIR}/01_isar.conf
    sed -i -e 's|##BUILDCHROOT##|${BUILDCHROOT_DIR}|g' ${WORKDIR}/01_isar.conf
    sed -i -e 's|##ROOTFS_DIR##|${ROOTFS_DIR}|g' ${WORKDIR}/01_isar.conf

    sed -i -e 's|##BUILDCHROOT_ID##|${BUILDCHROOT_ID}|g' ${WORKDIR}/01_isar.conf
    sed -i -e 's|##ROOTFS_ID##|${ROOTFS_ID}|g' ${WORKDIR}/01_isar.conf

    [ -d "/etc/schroot/chroot.d" ] || bbfatal "Config directory /etc/schroot/chroot.d not available."
    sudo install -m 0644 ${WORKDIR}/01_isar.conf /etc/schroot/chroot.d/01_isar.conf

}
addtask do_setup_schroot after do_unpack before do_build