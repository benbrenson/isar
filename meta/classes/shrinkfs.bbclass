# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

# This class implements functionalities for shrinking the release root filesystem
POST_ROOTFS_TASKS += "do_shrinkfs;"


do_shrinkfs() {
    apt-get clean

}
addtask do_shrinkfs
do_shrinkfs[stamp-extra-info] = "${MACHINE}.chroot"
do_shrinkfs[chroot] = "1"
do_shrinkfs[chrootdir] = "${ROOTFS_DIR}"