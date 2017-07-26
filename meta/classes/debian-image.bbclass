# This software is a part of ISAR.
# Copyright (C) 2017 Mixed-Mode GmbH

inherit wic useradd

DEPENDS += " ${IMAGE_INSTALL} "
S       = "${ROOTFS_DIR}"

KERNEL_IMAGE ?= ""
INITRD_IMAGE ?= ""

INIT = "${@bb.utils.contains('IMAGE_FEATURES', 'systemd', 'systemd systemd-sysv', 'sysvinit-core sysvinit-utils', d)}"
IMAGE_PREINSTALL += " ${INIT} "
IMAGE_INSTALL ?= ""



# Change to / inside chroot.
PP="/"
SCHROOT_ID = "${ROOTFS_ID}"

do_rootfs() {
    # Copy config file
    install -m 644 ${THISDIR}/files/multistrap.conf.in ${WORKDIR}/multistrap.conf
    install -m 755 ${THISDIR}/files/${DISTRO_CONFIG_SCRIPT} ${WORKDIR}/configscript.sh
    install -m 755 ${THISDIR}/files/setup.sh ${WORKDIR}

    # Adjust multistrap config
    sed -i 's|##IMAGE_PREINSTALL##|${IMAGE_PREINSTALL}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO##|${DISTRO}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_APT_SOURCE##|${DISTRO_APT_SOURCE}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_SUITE##|${DISTRO_SUITE}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_COMPONENTS##|${DISTRO_COMPONENTS}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##CONFIG_SCRIPT##|./tmp/work/${PN}-${PV}-${PR}/configscript.sh|' ${WORKDIR}/multistrap.conf
    sed -i 's|##SETUP_SCRIPT##|./tmp/work/${PN}-${PV}-${PR}/setup.sh|' ${WORKDIR}/multistrap.conf

    # Multistrap config use relative paths, so ensure that we are in the right folder
    cd ${TOPDIR}

    # Create root filesystem
    sudo multistrap -a ${DISTRO_ARCH} -d "${S}" -f "${WORKDIR}/multistrap.conf" || true

    # Configure root filesystem
    sudo chroot ${S} /configscript.sh ${MACHINE_SERIAL}
    sudo rm ${S}/configscript.sh
}
addtask rootfs before do_populate
do_rootfs[stamp-extra-info] = "${MACHINE}"
do_rootfs[depends] = "schroot:do_setup_schroot"


# Install Debian packages, that were built from sources
do_populate() {
    if [ -n "${IMAGE_INSTALL}" ]; then
        sudo mkdir -p ${S}/deb

        for p in ${IMAGE_INSTALL}; do
            sudo cp ${DEPLOY_DIR_DEB}/${p}_*.deb ${S}/deb
        done

        sudo chroot ${S} taskset 01 /usr/bin/dpkg -i -R /deb

        sudo rm -rf ${S}/deb
    fi
}
addtask populate before do_build
do_populate[stamp-extra-info] = "${MACHINE}"
do_populate[deptask] = "do_install"

# Post tasks running after all other important base tasks have finished.
# It is useful for doing late stuff like modifying, customizing or cleaning
# the root filesystem.
python do_post_rootfs(){
    post_tasks = d.getVar('POST_ROOTFS_TASKS', True)
    bb.note('Running last tasks on rootfs. (%s)' % post_tasks)
    for task in post_tasks.strip().split(';'):
            task = task.strip()

            if task != '':
                if not d.getVar(task,'True'):
                    bb.fatal('Task %s not found.' % task)

                bb.note("Executing %s() ..." % task)
                bb.build.exec_func(task, d)

}
addtask do_post_rootfs after do_populate before do_build


# cleaning of ROOTFS_DIR
do_clean_append() {

    rootfs_dir = d.getVar('ROOTFS_DIR', True)
    err = False

    if shell.call(['mountpoint', rootfs_dir + '/dev']) == 0:
        err = True
    elif shell.call(['mountpoint', rootfs_dir + '/dev/pts']) == 0:
        err = True
    elif shell.call(['mountpoint', rootfs_dir + '/proc']) == 0:
        err = True
    elif shell.call(['mountpoint', rootfs_dir + '/dev/pts']) == 0:
        err = True
    elif shell.call(['mountpoint', rootfs_dir + '/etc/resolv.conf']) == 0:
        err = True

    if err == True:
        bb.fatal('Cleaning ROOTFS_DIR not possible. Still busy.')

    shell.call(['sudo', 'rm', '-rf', rootfs_dir])
}

do_cleanall_append() {

    rootfs_dir = d.getVar('ROOTFS_DIR', True)
    err = False

    if shell.call(['mountpoint', rootfs_dir + '/dev']) == 0:
        err = True
    elif shell.call(['mountpoint', rootfs_dir + '/dev/pts']) == 0:
        err = True
    elif shell.call(['mountpoint', rootfs_dir + '/proc']) == 0:
        err = True
    elif shell.call(['mountpoint', rootfs_dir + '/dev/pts']) == 0:
        err = True
    elif shell.call(['mountpoint', rootfs_dir + '/etc/resolv.conf']) == 0:
        err = True

    if err == True:
        bb.fatal('Cleaning ROOTFS_DIR not possible. Still busy.')

    shell.call(['sudo', 'rm', '-rf', rootfs_dir])
}