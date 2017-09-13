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
                           autoconf \
                           gnupg \
                           vim \
                           flex \
                           git \
                           bison \
                           bc \
                           u-boot-tools \
                           pkg-config \
                           ca-certificates \
                           python \
                           python3 \
                           cmake \
                           vim \
                           "


# Some packages are only installable after late configurations for
# apt
BUILDCHROOT_POSTINSTALL ?= "crossbuild-essential-${DISTRO_ARCH} \
                            devscripts"

WORKDIR = "${TMPDIR}/work/${PF}/${DISTRO}"

APT_SRC_DIR = "${CROSS_BUILDCHROOT_DIR}/etc/apt/sources.list.d/"
APT_SRC_FILE = "${APT_SRC_DIR}/local.list"

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
    sudo mkdir -p ${CROSS_BUILDCHROOT_DIR}/usr/bin
    sudo cp /usr/bin/qemu-arm-static ${CROSS_BUILDCHROOT_DIR}/usr/bin

    # Create root filesystem
    sudo multistrap -a ${DEB_HOST_ARCH} -d "${CROSS_BUILDCHROOT_DIR}" -f "${WORKDIR}/multistrap.conf" || true

}
addtask do_buildchroot before do_setup_buildchroot
do_buildchroot[stamp-extra-info] = "${DISTRO}"
do_buildchroot[dirs] += "${SYSROOT}"


do_setup_buildchroot() {

  # Prevent daemons from starting in buildchroot
  if [ -x "${CROSS_BUILDCHROOT_DIR}/sbin/start-stop-daemon" ]; then
      echo "initctl: Trying to prevent daemons from starting in ${CROSS_BUILDCHROOT_DIR}"

      # Disable start-stop-daemon
      sudo mv ${CROSS_BUILDCHROOT_DIR}/sbin/start-stop-daemon ${CROSS_BUILDCHROOT_DIR}/sbin/start-stop-daemon.REAL
      sudo tee ${CROSS_BUILDCHROOT_DIR}/sbin/start-stop-daemon > /dev/null  << EOF
#!/bin/sh
echo
echo Warning: Fake start-stop-daemon called, doing nothing
EOF
      sudo chmod 755 ${CROSS_BUILDCHROOT_DIR}/sbin/start-stop-daemon
  fi

  if [ -x "${CROSS_BUILDCHROOT_DIR}/sbin/initctl" ]; then
      echo "start-stop-daemon: Trying to prevent daemons from starting in ${CROSS_BUILDCHROOT_DIR}"

      # Disable initctl
      sudo mv "${CROSS_BUILDCHROOT_DIR}/sbin/initctl" "${CROSS_BUILDCHROOT_DIR}/sbin/initctl.REAL"
      sudo tee ${CROSS_BUILDCHROOT_DIR}/sbin/initctl > /dev/null << EOF
#!/bin/sh
echo
echo "Warning: Fake initctl called, doing nothing"
EOF
      sudo chmod 755 ${CROSS_BUILDCHROOT_DIR}/sbin/initctl
  fi

  # Define sysvinit policy 101 to prevent daemons from starting in buildchroot
  if [ -x "${CROSS_BUILDCHROOT_DIR}/sbin/init" -a ! -f "${CROSS_BUILDCHROOT_DIR}/usr/sbin/policy-rc.d" ]; then
    echo "sysvinit: Using policy-rc.d to prevent daemons from starting in ${CROSS_BUILDCHROOT_DIR}"

    sudo tee ${CROSS_BUILDCHROOT_DIR}/usr/sbin/policy-rc.d > /dev/null << EOF
#!/bin/sh
echo "sysvinit: All runlevel operations denied by policy" >&2
exit 101
EOF
    sudo chmod a+x ${CROSS_BUILDCHROOT_DIR}/usr/sbin/policy-rc.d
  fi

  # Set hostname
  sudo sh -c 'echo "isar" > ${CROSS_BUILDCHROOT_DIR}/etc/hostname'

  # Create packages build folder
  sudo install -m 0777 -d ${CROSS_BUILDCHROOT_DIR}/home/builder

  # Create deb folder for installing potential dependencies
  sudo install -m 0777 -d ${CROSS_BUILDCHROOT_DIR}${CHROOT_DEPLOY_DIR_DEB}

  # Add local apt repository for auto install dependencies
  sudo install -m 0755 -d ${APT_SRC_DIR}
  install -m 0755 -d ${DEPLOY_DIR_DEB}/${DISTRO_ARCH}
  install -m 0755 -d ${DEPLOY_DIR_DEB}/${DEB_HOST_ARCH}
  sudo sh -c 'echo "deb [ trusted=yes ] file:${CHROOT_DEPLOY_DIR_DEB}/${DEB_HOST_ARCH}/ ./" > ${APT_SRC_FILE}'
  sudo sh -c 'echo "deb [ trusted=yes ] file:${CHROOT_DEPLOY_DIR_DEB}/${DISTRO_ARCH}/ ./" >> ${APT_SRC_FILE}'
  touch ${DEPLOY_DIR_DEB}/${DEB_HOST_ARCH}/Packages
  touch ${DEPLOY_DIR_DEB}/${DISTRO_ARCH}/Packages

  # Install host networking settings
  sudo cp /etc/resolv.conf ${CROSS_BUILDCHROOT_DIR}/etc

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

    rm -f /etc/dpkg/dpkg.cfg.d/multiarch

    #configuring packages
    dpkg --configure -a
    dpkg --configure -a
    apt-get update


    # Configure root filesystem for cross compiling
    # multistraps multiarch is not working
    dpkg --add-architecture ${DISTRO_ARCH}
    echo "Acquire::AllowInsecureRepositories \"true\";" > /etc/apt/apt.conf.d/10allowunauth

    apt-get update
    apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" ${BUILDCHROOT_POSTINSTALL}
}
addtask do_configure_buildchroot before do_build
do_configure_buildchroot[stamp-extra-info] = "${DISTRO}.chroot"
do_configure_buildchroot[chroot] = "1"
do_configure_buildchroot[id] = "${CROSS_BUILDCHROOT_ID}"


do_install() {
  :
}
addtask do_install after do_build