# This software is a part of ISAR.
# Copyright (C) 2017 Mixed-Mode GmbH

inherit wic useradd pkg-tune-task shrinkfs fetch

DEPENDS += " ${IMAGE_INSTALL} "
S       = "${ROOTFS_DIR}"

KERNEL_IMAGE ?= ""
INITRD_IMAGE ?= ""

INIT = "${@bb.utils.contains('IMAGE_FEATURES', 'systemd', 'systemd systemd-sysv', 'sysvinit-core sysvinit-utils', d)}"
IMAGE_PREINSTALL += " ${INIT} "
IMAGE_INSTALL ?= ""



# Change to / inside chroot.
PP="/"


# Multistrap based creation of rootfs
do_rootfs() {
    # Copy config file
    install -m 644 ${THISDIR}/files/multistrap.conf.in ${WORKDIR}/multistrap.conf

     # For now allow insecure repositories
    bbwarn "Allowing insecure repositories for rootfs during multistrap"
    install -m 755 -d ${ROOTFS_DIR}/etc/apt/apt.conf.d/
    echo 'Acquire::AllowInsecureRepositories "1";' > ${ROOTFS_DIR}/etc/apt/apt.conf.d/01unsecure

    # Adjust multistrap config
    sed -i 's|##IMAGE_PREINSTALL##|${IMAGE_PREINSTALL}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO##|${DISTRO}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_APT_SOURCE##|${DISTRO_APT_SOURCE}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_SUITE##|${DISTRO_SUITE}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_COMPONENTS##|${DISTRO_COMPONENTS}|' ${WORKDIR}/multistrap.conf

    # Install QEMU emulator to execute ARM binaries
    sudo mkdir -p ${ROOTFS_DIR}/usr/bin
    sudo cp /usr/bin/qemu-arm-static ${ROOTFS_DIR}/usr/bin


    # Create root filesystem
    sudo multistrap -a ${DISTRO_ARCH} -d "${S}" -f "${WORKDIR}/multistrap.conf" || true

    sudo rm ${ROOTFS_DIR}/etc/apt/apt.conf.d/01unsecure
}
addtask rootfs before do_setup_rootfs
do_rootfs[stamp-extra-info] = "${MACHINE}"
do_rootfs[depends] = "schroot:do_setup_schroot"


# First rootfs setup steps
do_setup_rootfs() {
# Prevent daemons from starting in buildchroot
  if [ -x "${ROOTFS_DIR}/sbin/start-stop-daemon" ]; then
      echo "initctl: Trying to prevent daemons from starting in ${ROOTFS_DIR}"

      # Disable start-stop-daemon
      sudo mv ${ROOTFS_DIR}/sbin/start-stop-daemon ${ROOTFS_DIR}/sbin/start-stop-daemon.REAL
      sudo tee ${ROOTFS_DIR}/sbin/start-stop-daemon > /dev/null  << EOF
#!/bin/sh
echo
echo Warning: Fake start-stop-daemon called, doing nothing
EOF
      sudo chmod 755 ${ROOTFS_DIR}/sbin/start-stop-daemon
  fi

  if [ -x "${ROOTFS_DIR}/sbin/initctl" ]; then
      echo "start-stop-daemon: Trying to prevent daemons from starting in ${ROOTFS_DIR}"

      # Disable initctl
      sudo mv "${ROOTFS_DIR}/sbin/initctl" "${ROOTFS_DIR}/sbin/initctl.REAL"
      sudo tee ${ROOTFS_DIR}/sbin/initctl > /dev/null << EOF
#!/bin/sh
echo
echo "Warning: Fake initctl called, doing nothing"
EOF
      sudo chmod 755 ${ROOTFS_DIR}/sbin/initctl
  fi

  # Define sysvinit policy 101 to prevent daemons from starting in buildchroot
  if [ -x "${ROOTFS_DIR}/sbin/init" -a ! -f "${ROOTFS_DIR}/usr/sbin/policy-rc.d" ]; then
    echo "sysvinit: Using policy-rc.d to prevent daemons from starting in ${ROOTFS_DIR}"

    sudo tee ${ROOTFS_DIR}/usr/sbin/policy-rc.d > /dev/null << EOF
#!/bin/sh
echo "sysvinit: All runlevel operations denied by policy" >&2
exit 101
EOF
    sudo chmod a+x ${ROOTFS_DIR}/usr/sbin/policy-rc.d
  fi

  # Set hostname
  sudo sh -c 'echo "isar" > ${ROOTFS_DIR}/etc/hostname'

  # Create packages build folder
  sudo install -m 0777 -d ${ROOTFS_DIR}/home/builder

  # Install host networking settings
  sudo cp /etc/resolv.conf ${ROOTFS_DIR}/etc
}
addtask do_setup_rootfs after do_rootfs before do_configure_rootfs
do_setup_rootfs[stamp-extra-info] = "${MACHINE}"


# Run late configurations on rootfs
do_configure_rootfs() {
    echo "LANG=en_US.UTF-8"     >> /etc/default/locale
    echo "LANGUAGE=en_US.UTF-8" >> /etc/default/locale
    echo "LC_ALL=C"             >> /etc/default/locale
    echo "LC_CTYPE=C"           >> /etc/default/locale
    echo "LANG=en_US.UTF-8"     >> /etc/default/locale

    ## Configuration file for localepurge(8)
    cat > /etc/locale.nopurge << EOF
# Remove localized man pages
MANDELETE

# Delete new locales which appear on the system without bothering you
DONTBOTHERNEWLOCALE

# Keep these locales after package installations via apt-get(8)
en
en_US
en_US.UTF-8
EOF

    debconf-set-selections <<END
locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8
locales locales/default_environment_locale select en_US.UTF-8
END

    # Set up non-interactive configuration
    export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
    export LC_ALL=C LANGUAGE=C LANG=C

    # Run pre installation script
    /var/lib/dpkg/info/dash.preinst install

    echo "running dpkg -a"
    dpkg --configure -a
    echo "running dpkg -a"
    dpkg --configure -a

    cat > /etc/fstab << "EOF"
# Begin /etc/fstab
#/dev/mmcblk0   /       ext4        defaults        1   1
proc        /proc       proc        nosuid,noexec,nodev 0   0
sysfs       /sys        sysfs       nosuid,noexec,nodev 0   0
devpts      /dev/pts    devpts      gid=5,mode=620      0   0
tmpfs       /run        tmpfs       defaults        0   0
devtmpfs    /dev        devtmpfs    mode=0755,nosuid    0   0

# End /etc/fstab
EOF

    # Don't install suggests and recommends
    cat > /etc/apt/apt.conf.d/10nosuggests << "EOF"
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF

    # Enable tty
    echo "T0:23:respawn:/sbin/getty -L ${MACHINE_SERIAL} 115200 vt100" >> /etc/inittab

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
addtask do_configure_rootfs after do_setup_rootfs before do_populate
do_configure_rootfs[stamp-extra-info] = "${MACHINE}.chroot"
do_configure_rootfs[chroot] = "1"
do_configure_rootfs[id] = "${ROOTFS_ID}"


# Install Debian packages, that were built from sources
IMAGE_INSTALL_DEBS="${@bb.utils.explode_dep_pkg_suffix(d.getVar('IMAGE_INSTALL', True), d)}"
do_populate() {
    if [ -n "${IMAGE_INSTALL_DEBS}" ]; then

        # Temporary add local sources for installing packages created by isar
        echo "deb [ trusted=yes ] file:${CHROOT_DEPLOY_DIR_DEB}/${DEB_HOST_ARCH}/ ./" > /etc/apt/sources.list.d/local.list
        echo "deb [ trusted=yes ] file:${CHROOT_DEPLOY_DIR_DEB}/${DISTRO_ARCH}/ ./" >> /etc/apt/sources.list.d/local.list

        apt-get update
        apt-get install -y ${IMAGE_INSTALL_DEBS}

        # Cleanup
        rm -f /etc/apt/sources.list.d/local.list
        apt-get update
    fi
}
addtask populate before do_post_rootfs
do_populate[stamp-extra-info] = "${MACHINE}"
do_populate[deptask] = "do_install"
do_populate[chroot] = "1"
do_populate[id] = "${ROOTFS_ID}"


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
addtask do_post_rootfs after do_populate before do_package_tunes



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
