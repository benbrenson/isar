# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

DESCRIPTION="Recipe for setting up schroot and required configs on the host build machine."

inherit fetch patch

SRC_URI = "file://01_isar.conf \
           file://fstab \
           file://nssdatabases \
           file://15binfmt \
           file://copyfiles \
           file://11resolv \
           file://10mount \
           file://50chrootname \
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

    sed -i -e 's|##DEPLOY_DEB##|${DEPLOY_DIR_DEB}|g' ${WORKDIR}/fstab
    sed -i -e 's|##CHROOT_DEPLOY_DEB##|${CHROOT_DEPLOY_DIR_DEB}|g' ${WORKDIR}/fstab

    [ -d "/etc/schroot/chroot.d" ] || bbfatal "Config directory /etc/schroot/chroot.d not available."

    sudo install -m 0644 ${WORKDIR}/01_isar.conf /etc/schroot/chroot.d/01_isar.conf
    sudo install -m 0644 ${WORKDIR}/fstab /etc/schroot/default/fstab
    sudo install -m 0644 ${WORKDIR}/copyfiles /etc/schroot/default/copyfiles
    sudo install -m 0644 ${WORKDIR}/nssdatabases /etc/schroot/default/nssdatabases
    sudo install -m 0755 ${WORKDIR}/15binfmt /etc/schroot/setup.d/15binfmt
    sudo install -m 0755 ${WORKDIR}/11resolv /etc/schroot/setup.d/11resolv
    sudo install -m 0755 ${WORKDIR}/10mount /etc/schroot/setup.d/10mount
    sudo install -m 0755 ${WORKDIR}/50chrootname /etc/schroot/setup.d/50chrootname

}
addtask do_setup_schroot after do_patch before do_build
do_setup_schroot[dirs] += "${DEPLOY_DIR_DEB}"
