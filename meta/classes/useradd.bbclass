# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

# This class implements common functionalities for adding/removing users.
POST_ROOTFS_TASKS_append= "do_useradd; do_set_root_password; "

USERADD_COMMAND ?= ""
DEFAULT_ROOT_PASSWORD ?= "toor"


do_useradd() {
    IFS=";"
    STR="${USERADD_COMMAND}"
    if [ -n "${USERADD_COMMAND}" ]
    then
        for cmd in $STR ; do
            eval useradd $cmd || true
        done
    else
        bbwarn "USERADD_COMMAND not given. Skipping creation of users."
    fi

}
addtask do_useradd
do_useradd[stamp-extra-info] = "${MACHINE}.chroot"
do_useradd[chroot] = "1"


do_set_root_password() {
    echo "root:${DEFAULT_ROOT_PASSWORD}" | chpasswd
}
addtask do_set_root_password
do_set_root_password[stamp-extra-info] = "${MACHINE}.chroot"
do_set_root_password[chroot] = "1"
do_set_root_password[chrootdir] = "${ROOTFS_DIR}"
