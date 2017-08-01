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

# Change to /home/builder inside chroot.
PP ="/home/builder"


do_buildchroot() {
    # Copy config files
    install -m 644 ${THISDIR}/files/multistrap.conf.in ${WORKDIR}/multistrap.conf

    # Adjust multistrap config
    sed -i 's|##BUILDCHROOT_PREINSTALL##|${BUILDCHROOT_PREINSTALL}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO##|${DISTRO}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_APT_SOURCE##|${DISTRO_APT_SOURCE}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_SUITE##|${DISTRO_SUITE}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_COMPONENTS##|${DISTRO_COMPONENTS}|' ${WORKDIR}/multistrap.conf

    # Install QEMU emulator to execute ARM binaries
    sudo mkdir -p ${BUILDCHROOT_DIR}/usr/bin
    sudo cp /usr/bin/qemu-arm-static ${BUILDCHROOT_DIR}/usr/bin

    # Create root filesystem
    sudo multistrap -a ${DISTRO_ARCH} -d "${BUILDCHROOT_DIR}" -f "${WORKDIR}/multistrap.conf" || true

}
addtask do_buildchroot before do_setup_buildchroot
do_buildchroot[stamp-extra-info] = "${DISTRO}"



do_setup_buildchroot() {

  # Prevent daemons from starting in buildchroot
  if [ -x "${BUILDCHROOT_DIR}/sbin/start-stop-daemon" ]; then
      echo "initctl: Trying to prevent daemons from starting in ${BUILDCHROOT_DIR}"

      # Disable start-stop-daemon
      sudo mv ${BUILDCHROOT_DIR}/sbin/start-stop-daemon ${BUILDCHROOT_DIR}/sbin/start-stop-daemon.REAL
      sudo tee ${BUILDCHROOT_DIR}/sbin/start-stop-daemon > /dev/null  << EOF
#!/bin/sh
echo
echo Warning: Fake start-stop-daemon called, doing nothing
EOF
      sudo chmod 755 ${BUILDCHROOT_DIR}/sbin/start-stop-daemon
  fi

  if [ -x "${BUILDCHROOT_DIR}/sbin/initctl" ]; then
      echo "start-stop-daemon: Trying to prevent daemons from starting in ${BUILDCHROOT_DIR}"

      # Disable initctl
      sudo mv "${BUILDCHROOT_DIR}/sbin/initctl" "${BUILDCHROOT_DIR}/sbin/initctl.REAL"
      sudo tee ${BUILDCHROOT_DIR}/sbin/initctl > /dev/null << EOF
#!/bin/sh
echo
echo "Warning: Fake initctl called, doing nothing"
EOF
      sudo chmod 755 ${BUILDCHROOT_DIR}/sbin/initctl
  fi

  # Define sysvinit policy 101 to prevent daemons from starting in buildchroot
  if [ -x "${BUILDCHROOT_DIR}/sbin/init" -a ! -f "${BUILDCHROOT_DIR}/usr/sbin/policy-rc.d" ]; then
    echo "sysvinit: Using policy-rc.d to prevent daemons from starting in ${BUILDCHROOT_DIR}"

    sudo tee ${BUILDCHROOT_DIR}/usr/sbin/policy-rc.d > /dev/null << EOF
#!/bin/sh
echo "sysvinit: All runlevel operations denied by policy" >&2
exit 101
EOF
    sudo chmod a+x ${BUILDCHROOT_DIR}/usr/sbin/policy-rc.d
  fi

  # Set hostname
  sudo sh -c 'echo "isar" > ${BUILDCHROOT_DIR}/etc/hostname'

  # Create packages build folder
  sudo install -m 0777 -d ${BUILDCHROOT_DIR}/home/builder

  # Install host networking settings
  sudo cp /etc/resolv.conf ${BUILDCHROOT_DIR}/etc

}
addtask do_setup_buildchroot before do_configure_buildchroot
do_setup_buildchroot[stamp-extra-info] = "${DISTRO}"



do_configure_buildchroot() {
    # Configure root filesystem
    echo "LANG=en_US.UTF-8"     >> /etc/default/locale
    echo "LANGUAGE=en_US.UTF-8" >> /etc/default/locale
    echo "LC_ALL=C"             >> /etc/default/locale
    echo "LC_CTYPE=C"           >> /etc/default/locale



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

#set up non-interactive configuration
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C

#run pre installation script
/var/lib/dpkg/info/dash.preinst install

#configuring packages
dpkg --configure -a
dpkg --configure -a
apt-get update
}
addtask do_configure_buildchroot before do_build
do_configure_buildchroot[stamp-extra-info] = "${DISTRO}.chroot"
do_configure_buildchroot[chroot] = "1"
do_configure_buildchroot[id] = "${BUILDCHROOT_ID}"