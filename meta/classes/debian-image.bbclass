# This software is a part of ISAR.
# Copyright (C) 2017-2018 Mixed-Mode GmbH

inherit rootfs image useradd pkg-tune-task shrinkfs

DEPENDS += " ${IMAGE_INSTALL} "
S = "${ROOTFS_DIR}"

INIT = "${@bb.utils.contains('IMAGE_FEATURES', 'systemd', 'systemd systemd-sysv', 'sysvinit-core sysvinit-utils', d)}"
IMAGE_PREINSTALL += " ${INIT} "
IMAGE_INSTALL ?= ""
BOOTLOADER_IMAGE ?= "virtual/bootloader"
KERNEL_IMAGE ?= "virtual/kernel"
INITRD_IMAGE ?= "initrd.img"

# Install Debian packages, that were built from sources
# replace suffixes (e.g. cross -> armhf)
IMAGE_INSTALL_DEBS = "${@oe.utils.convert_virtuals(d.getVar('IMAGE_INSTALL', True), d)}"
IMAGE_INSTALL_DEBS_FINAL = "${@oe.utils.prune_suffixes(d.getVar('IMAGE_INSTALL_DEBS', True), d.getVar('SPECIAL_PKGSUFFIX', True), '',d)}"


# Change to / inside chroot.
PP="/"
ROOT_DIR = "${ROOTFS_DIR}"
CHROOT_ID = "${ROOTFS_ID}"
ARCH = "${DISTRO_ARCH}"
INSTALL = "${ESSENTIAL_INSTALL} ${IMAGE_PREINSTALL} ${IMAGE_INSTALL_DEBS_FINAL}"

CACHE_PREINSTALL = "${ESSENTIAL_INSTALL} ${IMAGE_PREINSTALL}"

IMAGE_LAYOUT_FILE ?= "image_layout.json"

SRC_URI += "file://${IMAGE_LAYOUT_FILE} \
            file://multistrap-isar-upstream.list.in"


do_configure_rootfs_append() {
    cat<<-__EOF__ >  /${sysconfdir}/fstab
		# Begin /etc/fstab
		#/dev/mmcblk0   /       ext4        defaults        1   1
		proc        /proc       proc        nosuid,noexec,nodev 0   0
		sysfs       /sys        sysfs       nosuid,noexec,nodev 0   0
		devpts      /dev/pts    devpts      gid=5,mode=620      0   0
		tmpfs       /run        tmpfs       defaults        0   0
		devtmpfs    /dev        devtmpfs    mode=0755,nosuid    0   0

		# End /etc/fstab
	__EOF__

    # Don't install suggests and recommends
    cat<<-__EOF__ > /${sysconfdir}/apt/apt.conf.d/10nosuggests
		APT::Install-Recommends "0";
		APT::Install-Suggests "0";
	__EOF__

    # Enable tty
    echo "T0:23:respawn:/sbin/getty -L ${MACHINE_SERIAL} 115200 vt100" >> /${sysconfdir}/inittab

    # Undo setup script changes
    if [ -x "/sbin/start-stop-daemon.REAL" ]; then
        mv -f /sbin/start-stop-daemon.REAL /sbin/start-stop-daemon
    fi

    if [ -x "/sbin/initctl.REAL" ]; then
        mv /sbin/initctl.REAL /sbin/initctl
    fi

    if [ -x "/sbin/init" -a -x "/usr/sbin/policy-rc.d" ]; then
        rm -f /usr/sbin/policy-rc.d
    fi
}


# Post tasks running after all other important base tasks have finished.
# It is useful for doing late stuff like modifying, customizing or cleaning
# the root filesystem.
python do_post_rootfs() {
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
addtask do_post_rootfs after do_configure_rootfs before do_package_tunes


#
# Do late configurations related to the local apt caches
#
do_finalize_cache() {
    # Only create upstream list file, when fetching packages from the cache.
    # On the very first build, those upstream sections are already created by multistrap
    if [ -e "${ISAR_FIRST_BUILD_DONE}" ] && [ "${REPRODUCIBLE_BUILD_ENABLED}" == "1" ]; then
        sed -e 's|##DISTRO_APT_SOURCE##|${DISTRO_APT_SOURCE}|g' \
            -e 's|##DISTRO_APT_SOURCE_SEC##|${DISTRO_APT_SOURCE_SEC}|g' \
            -e 's|##DISTRO_SUITE##|${DISTRO_SUITE}|' \
            -e 's|##DISTRO_COMPONENTS##|${DISTRO_COMPONENTS}|g' \
            ${WORKDIR}/multistrap-isar-upstream.list.in > \
            ${WORKDIR}/multistrap-isar-upstream.list

        sudo install -m 644 ${WORKDIR}/multistrap-isar-upstream.list \
                     ${ROOT_DIR}/${sysconfdir}/apt/sources.list.d/
    fi

    sudo rm -f ${ROOT_DIR}/${sysconfdir}/apt/sources.list.d/multistrap-${DISTRO_CACHE_SECTION}.list

    # Adding last packages, installed during do_install_deps() tasks
    stage_packages ${ROOT_DIR} ${CACHE_STAGING_DIR}/
    stage_packages ${BUILDCHROOT_DIR} ${CACHE_STAGING_DIR}/
    stage_packages ${CROSS_BUILDCHROOT_DIR} ${CACHE_STAGING_DIR}/

    cache_add_package ${ISAR_REPO_LOCAL} \
                      ${ISAR_CACHE_LOCAL_PREFIX} \
                      ${CACHE_STAGING_DIR}/

    cache_create_snapshot
}
addtask do_finalize_cache after do_install before do_build


SWUPDATE_DEPLOY_DIR ?= "${DEPLOY_DIR_IMAGE}/update"
#
# Only run when override 'update' set
# TODO: Add overwrite 'update'
#
python do_image_swupdate() {
    import subprocess
    import glob

    generate_image = bb.utils.contains('IMAGE_FEATURES', 'update' ,'true', 'false', d)
    updateable_fstypes = d.getVar('UPDATEABLE_FSTYPES', True)
    datetime = d.getVar('DATETIME', True)
    swupdate_deploy_dir = d.getVar('SWUPDATE_DEPLOY_DIR', True)
    cwd = os.getcwd()

    os.chdir(d.getVar('DEPLOY_DIR_IMAGE', True))
    if generate_image == "true":
        for fstype in updateable_fstypes.split():
            for fn in glob.glob('*.' + fstype + '.%s' % datetime):

                filebasename= fn.replace('.%s' % datetime, '')
                files='sw-description %s' % fn
                ret = subprocess.call('bash -c "for i in %s ; do echo \$i ; done | cpio -ovL -H crc >  %s/%s.swu"' % (files, swupdate_deploy_dir, fn), shell=True)

                try:
                    os.unlink('%s/%s.swu' % (swupdate_deploy_dir, filebasename))
                except FileNotFoundError:
                    pass

                os.symlink('%s.swu' % fn, '%s/%s.swu' % (swupdate_deploy_dir, filebasename))
    else:
        bb.warn('Skipping creation of swupdate files.')

    os.chdir(cwd)

}
addtask do_image_swupdate after do_image before do_build
do_image_swupdate[dirs] += "${SWUPDATE_DEPLOY_DIR}"

do_build() {
    if [ ! -e "${ISAR_FIRST_BUILD_DONE}" ]; then
        touch ${ISAR_FIRST_BUILD_DONE}
    fi
}