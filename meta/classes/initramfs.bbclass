# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH


IMAGE_PREINSTALL_append = " initramfs-tools "

INITRAMFS_BASE_NAME = "initrd"

# initramfs.conf settings
CFG_FILE ?= "/etc/initramfs-tools/initramfs.conf"
CFG_MODULES ?= "most"
CFG_BUSYBOX ?= "auto"
CFG_KEYMAP  ?= "n"
CFG_COMPRESS ?= "gzip"
CFG_DEVICE  ?= ""
CFG_ROOT    ?= ""

CFG_NFSROOT ?= "auto"

# update-initramfs.conf
CFG_UPDATE_FILE   ?= "/etc/initramfs-tools/update-initramfs.conf"
CFG_UPDATE_UPDATE ?= "yes"
CFG_UPDATE_BACKUP ?= "no"

do_prepare_initramfs() {
    # prepare initramfs.conf
    sed -i -e 's/MODULES=.*$/MODULES=${CFG_MODULES}/g'  ${CFG_FILE}
    sed -i -e 's/BUSYBOX=.*$/BUSYBOX=${CFG_BUSYBOX}/g'  ${CFG_FILE}
    sed -i -e 's/KEYMAP=.*$/KEYMAP=${CFG_KEYMAP}/g'     ${CFG_FILE}
    sed -i -e 's/COMPRESS=.*$/COMPRESS=${CFG_COMPRESS}/g'   ${CFG_FILE}
    sed -i -e 's/DEVICE=.*$/DEVICE=${CFG_DEVICE}/g'     ${CFG_FILE}
    sed -i -e 's/NFSROOT=.*$/NFSROOT=${CFG_NFSROOT}/g'   ${CFG_FILE}

    echo "ROOT=${CFG_ROOT}" >> ${CFG_FILE}


    # prepare update-initramfs.conf
    sed -i -e 's/update_initramfs=.*$/update_initramfs=${CFG_UPDATE_UPDATE}/g'  ${CFG_UPDATE_FILE}
    sed -i -e 's/backup_initramfs=.*$/backup_initramfs=${CFG_UPDATE_BACKUP}/g'  ${CFG_UPDATE_FILE}

}
addtask do_prepare_initramfs after do_populate before do_generate_initramfs
do_prepare_initramfs[stamp-extra-info] = "${DISTRO}.chroot"
do_prepare_initramfs[chroot] = "1"
do_prepare_initramfs[id] = "${ROOTFS_ID}"


do_generate_initramfs() {

    LINUX_VERSION=$(dpkg-query --showformat='${Version}' --show linux-image || true)
    if [ -n "${LINUX_VERSION}" ]; then
        rm -rf /boot/initrd.img-${LINUX_VERSION}
        update-initramfs -k ${LINUX_VERSION} -c
    else
        bbwarn "No linux version detected... skipping update-initramfs."
    fi
}
addtask do_generate_initramfs after do_prepare_initramfs before do_post_rootfs
do_generate_initramfs[stamp-extra-info] = "${DISTRO}.chroot"
do_generate_initramfs[chroot] = "1"
do_generate_initramfs[id] = "${ROOTFS_ID}"