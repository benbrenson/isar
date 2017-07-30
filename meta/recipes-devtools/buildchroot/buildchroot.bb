# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

# Root filesystem for packages building

DESCRIPTION = "Multistrap development filesystem"

DEPENDS += "schroot"
do_build[deptask]="do_build"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

BUILDCHROOT_PREINSTALL ?= "gcc \
                           make \
                           build-essential \
                           debhelper \
                           autotools-dev \
                           dpkg \
                           locales \
                           docbook-to-man \
                           apt \
                           automake \
                           gnupg"

WORKDIR = "${TMPDIR}/work/${PF}/${DISTRO}"
do_build[stamp-extra-info] = "${DISTRO}"

do_buildchroot() {
    # Copy config files
    install -m 644 ${THISDIR}/files/multistrap.conf.in ${WORKDIR}/multistrap.conf
    install -m 755 ${THISDIR}/files/configscript.sh ${WORKDIR}
    install -m 755 ${THISDIR}/files/setup.sh ${WORKDIR}

    # Adjust multistrap config
    sed -i 's|##BUILDCHROOT_PREINSTALL##|${BUILDCHROOT_PREINSTALL}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO##|${DISTRO}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_APT_SOURCE##|${DISTRO_APT_SOURCE}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_SUITE##|${DISTRO_SUITE}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_COMPONENTS##|${DISTRO_COMPONENTS}|' ${WORKDIR}/multistrap.conf
    #sed -i 's|##CONFIG_SCRIPT##|./tmp/work/${PF}/${DISTRO}/configscript.sh|' ${WORKDIR}/multistrap.conf
    #sed -i 's|##SETUP_SCRIPT##|./tmp/work/${PF}/${DISTRO}/setup.sh|' ${WORKDIR}/multistrap.conf

    # Multistrap config use relative paths, so ensure that we are in the right folder
    #cd ${TOPDIR}
    # Install QEMU emulator to execute ARM binaries
    sudo mkdir -p ${BUILDCHROOT_DIR}/usr/bin
    sudo cp /usr/bin/qemu-arm-static ${BUILDCHROOT_DIR}/usr/bin

    # Create root filesystem
    sudo multistrap -a ${DISTRO_ARCH} -d "${BUILDCHROOT_DIR}" -f "${WORKDIR}/multistrap.conf" || true

}
addtask do_buildchroot before do_setup_buildchroot



do_setup_buildchroot() {

  # Prevent daemons from starting in buildchroot
  if [ -x "${BUILDCHROOT_DIR}/sbin/start-stop-daemon" ]; then
      echo "initctl: Trying to prevent daemons from starting in ${BUILDCHROOT_DIR}"

      # Disable start-stop-daemon
      mv ${BUILDCHROOT_DIR}/sbin/start-stop-daemon ${BUILDCHROOT_DIR}/sbin/start-stop-daemon.REAL
      cat > ${BUILDCHROOT_DIR}/sbin/start-stop-daemon << EOF
      #!/bin/sh
      echo
      echo Warning: Fake start-stop-daemon called, doing nothing
      EOF
      chmod 755 ${BUILDCHROOT_DIR}/sbin/start-stop-daemon
  fi

  if [ -x "${BUILDCHROOT_DIR}/sbin/initctl" ]; then
      echo "start-stop-daemon: Trying to prevent daemons from starting in ${BUILDCHROOT_DIR}"

      # Disable initctl
      mv "${BUILDCHROOT_DIR}/sbin/initctl" "${BUILDCHROOT_DIR}/sbin/initctl.REAL"
      cat > ${BUILDCHROOT_DIR}/sbin/initctl << EOF
      #!/bin/sh
      echo
      echo "Warning: Fake initctl called, doing nothing"
      EOF
      chmod 755 ${BUILDCHROOT_DIR}/sbin/initctl
  fi

  # Define sysvinit policy 101 to prevent daemons from starting in buildchroot
  if [ -x "${BUILDCHROOT_DIR}/sbin/init" -a ! -f "${BUILDCHROOT_DIR}/usr/sbin/policy-rc.d" ]; then
    echo "sysvinit: Using policy-rc.d to prevent daemons from starting in ${BUILDCHROOT_DIR}"

    cat > ${BUILDCHROOT_DIR}/usr/sbin/policy-rc.d << EOF
    #!/bin/sh
    echo "sysvinit: All runlevel operations denied by policy" >&2
    exit 101
    EOF
    chmod a+x ${BUILDCHROOT_DIR}/usr/sbin/policy-rc.d
  fi

  # Set hostname
  echo "isar" > ${BUILDCHROOT_DIR}/etc/hostname

  # Create packages build folder
  sudo install -d ${BUILDCHROOT_DIR}/home/builder
  sudo chmod -R a+rw ${BUILDCHROOT_DIR}/home/builder

  # Install host networking settings
  sudo cp /etc/resolv.conf ${BUILDCHROOT_DIR}/etc

}
addtask do_setup_buildchroot before do_config_buildchroot



do_config_buildchroot() {
    # Configure root filesystem
    sudo chroot ${BUILDCHROOT_DIR} /configscript.sh
}
addtask do_config_buildchroot before do_build