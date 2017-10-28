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
do_useradd[chrootdir] = "${ROOTFS_DIR}"


do_set_root_password() {
    PASS=$(openssl passwd -1 -salt xyz ${DEFAULT_ROOT_PASSWORD})

    if [ -e ${ROOTFS_DIR}/etc/shadow ]; then
        sed -i "s%^root:\*:%root:$PASS:%" ${ROOTFS_DIR}/etc/shadow
        fi
}
addtask do_set_root_password
do_set_root_password[stamp-extra-info] = "${MACHINE}"

