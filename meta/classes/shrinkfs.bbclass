# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

# This class implements functionality for shrinking the release root filesystem
POST_ROOTFS_TASKS += "do_shrinkfs;"


do_shrinkfs() {
    bbnote "Nothing implemented yet."
}
addtask do_shrinkfs
do_shrinkfs[stamp-extra-info] = "${MACHINE}.chroot"
do_shrinkfs[chroot] = "1"
do_shrinkfs[id] = "${ROOTFS_ID}"