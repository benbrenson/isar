# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH


IMAGE_PREINSTALL_append = " initramfs-tools "

# initramfs.conf settings
CFG_FILE_INITRAMFS ?= "/etc/initramfs-tools/initramfs.conf"
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
    sed -i -e 's/MODULES=.*$/MODULES=${CFG_MODULES}/g' \
        -e 's/BUSYBOX=.*$/BUSYBOX=${CFG_BUSYBOX}/g' \
        -e 's/KEYMAP=.*$/KEYMAP=${CFG_KEYMAP}/g' \
        -e 's/COMPRESS=.*$/COMPRESS=${CFG_COMPRESS}/g' \
        -e 's/DEVICE=.*$/DEVICE=${CFG_DEVICE}/g' \
        -e 's/NFSROOT=.*$/NFSROOT=${CFG_NFSROOT}/g' \
        ${CFG_FILE_INITRAMFS}

    echo "ROOT=${CFG_ROOT}" >> ${CFG_FILE_INITRAMFS}


    # prepare update-initramfs.conf
    sed -i -e 's/update_initramfs=.*$/update_initramfs=${CFG_UPDATE_UPDATE}/g' \
        -e 's/backup_initramfs=.*$/backup_initramfs=${CFG_UPDATE_BACKUP}/g' \
        ${CFG_UPDATE_FILE}

}
addtask do_prepare_initramfs after do_configure_rootfs before do_generate_initramfs
do_prepare_initramfs[stamp-extra-info] = "${DISTRO}.chroot"
do_prepare_initramfs[chroot] = "1"
do_prepare_initramfs[id] = "${ROOTFS_ID}"

LINUX_IMAGE ?= "${@oe.utils.prune_suffixes(d.getVar('PREFERRED_PROVIDER_virtual/kernel', True), '-cross', '', d)}"
do_generate_initramfs() {

    LINUX_VERSION=$(dpkg-query --showformat='${Version}' --show ${LINUX_IMAGE} || true)
    bbwarn "${LINUX_IMAGE}"
    if [ -n "${LINUX_VERSION}" ]; then
        rm -rf /boot/${INITRD_IMAGE}-${LINUX_VERSION}
        update-initramfs -k ${LINUX_VERSION} -c
    else
        bbwarn "No linux version detected... skipping update-initramfs."
    fi
}
addtask do_generate_initramfs after do_prepare_initramfs before do_post_rootfs
do_generate_initramfs[stamp-extra-info] = "${DISTRO}.chroot"
do_generate_initramfs[chroot] = "1"
do_generate_initramfs[id] = "${ROOTFS_ID}"