# This software is a part of ISAR.
# Copyright (C) 2017-2018 Mixed-Mode GmbH
#
# Implementation for setting up a root filesystem.
#
inherit apt-cache fetch

# Create dependency chain
do_rootfs[deptask] = "do_install"

ESSENTIAL_INSTALL ?= "base-files base-passwd bash bsdutils coreutils bash debianutils \
                      diffutils apt findutils grep gzip hostname init-system-helpers \
                      libc-bin perl-base sed tar util-linux mawk diffutils \
                      "

BUILDCHROOT_PREINSTALL ?= "\
    ${ESSENTIAL_INSTALL} \
    gcc \
    make \
    build-essential \
    debhelper \
    devscripts \
    equivs \
    autotools-dev \
    locales \
    docbook-to-man \
    automake \
    autoconf \
    gnupg \
    flex \
    git \
    bison \
    bc \
    u-boot-tools \
    pkg-config \
    ca-certificates \
    python python3 python-pip python3-pip python-setuptools python3-setuptools \
    cmake \
    vim \
    "

APT_SRC_DIR ?= "${ROOT_DIR}/etc/apt/sources.list.d"
APT_SRC_FILE ?= "${APT_SRC_DIR}/local.list"

SRC_URI += "file://multistrap.conf.in"


do_install_keyrings() {
    if [ -z "${DISTRO_KEYRINGS}" ]; then
        return
    fi

    sudo mkdir -p ${ROOT_DIR}/${sysconfdir}/apt/trusted.gpg.d
    sudo mkdir -p ${ROOT_DIR}/tmp/keyrings

    for keyring in `eval echo ${DISTRO_KEYRINGS}`
    do
        cd ${ROOT_DIR}/tmp
        sudo apt-get download -y ${keyring}
        deb=`ls ${keyring}_*.deb`
        sudo dpkg -X $deb ${ROOT_DIR}/tmp/keyrings
        sudo cp -r ${ROOT_DIR}/tmp/keyrings/usr/share/keyrings/*    ${ROOT_DIR}/${sysconfdir}/apt/trusted.gpg.d || true
        sudo cp -r ${ROOT_DIR}/tmp/keyrings/${sysconfdir}/apt/trusted.gpg.d/* ${ROOT_DIR}/${sysconfdir}/apt/trusted.gpg.d || true
        sudo rm -r $deb ${ROOT_DIR}/tmp/keyrings
    done
}


do_rootfs() {

	# Fix errors due to non authorized package repository.
	# Isar local repository is not signed and it makes no sence
	# when doing so...
    sudo mkdir -p ${ROOT_DIR}/${sysconfdir}/apt/apt.conf.d
    cat<<-__EOF__ | sudo tee ${ROOT_DIR}/${sysconfdir}/apt/apt.conf.d/01unprivileged
		Acquire::AllowInsecureRepositories "true";
		APT::Get::AllowUnauthenticated "true";
	__EOF__

    # Adjust multistrap config
    sed -e 's|##INSTALL##|${INSTALL}|g' \
        -e 's|##DISTRO_APT_SOURCE##|${DISTRO_APT_SOURCE}|g' \
        -e 's|##DISTRO_APT_SOURCE_SEC##|${DISTRO_APT_SOURCE_SEC}|g' \
        -e 's|##DISTRO_APT_SOURCE_CACHE_ISAR##|copy:///${CACHE_DIR}/public/${ISAR_CACHE_LOCAL_PREFIX}|g' \
        -e 's|##DISTRO_SUITE##|${DISTRO_SUITE}|' \
        -e 's|##DISTRO_COMPONENTS##|${DISTRO_COMPONENTS}|g' \
        -e 's|##DISTRO_CACHE_SECTION##|${DISTRO_CACHE_SECTION}|g' \
        ${WORKDIR}/multistrap.conf.in > ${WORKDIR}/multistrap.conf


    if [ -e "${ISAR_FIRST_BUILD_DONE}" ] && [ "${REPRODUCIBLE_BUILD_ENABLED}" == "1" ]; then
        # Set all config file sections to download from the cache
        bootstrap="${DISTRO_CACHE_SECTION}"
        aptsources="${DISTRO_CACHE_SECTION}"
    else
        bootstrap="${DISTRO_REMOTE_SECTIONS} ${DISTRO_CACHE_SECTION}"
        aptsources="${DISTRO_REMOTE_SECTIONS} ${DISTRO_CACHE_SECTION}"
    fi

    sed -i -e "s|##DISTRO_MULTICONF_BOOTSTRAP##|$bootstrap|g" \
           -e "s|##DISTRO_MULTICONF_APTSOURCES##|$aptsources|g" \
           ${WORKDIR}/multistrap.conf

    # Install QEMU emulator to execute ARM binaries
    sudo mkdir -p ${ROOT_DIR}/usr/bin
    sudo cp /usr/bin/qemu-arm-static ${ROOT_DIR}/usr/bin

    # Create root filesystem.
    sudo multistrap -a ${ARCH} -d "${ROOT_DIR}" -f "${WORKDIR}/multistrap.conf" || true
}
addtask do_rootfs after do_unpack before do_setup_rootfs
do_rootfs[stamp-extra-info] = "${DISTRO}"
do_rootfs[prefuncs] += "do_install_keyrings"


do_setup_rootfs() {
    # Prevent daemons from starting in buildchroot
    if [ -x "${ROOT_DIR}/sbin/start-stop-daemon" ]; then
        echo "initctl: Trying to prevent daemons from starting in ${ROOT_DIR}"

        # Disable start-stop-daemon
        sudo mv ${ROOT_DIR}/sbin/start-stop-daemon ${ROOT_DIR}/sbin/start-stop-daemon.REAL
        sudo tee ${ROOT_DIR}/sbin/start-stop-daemon > /dev/null  <<-__EOF__
			#!/bin/sh
			echo
			echo Warning: Fake start-stop-daemon called, doing nothing
		__EOF__
        sudo chmod 755 ${ROOT_DIR}/sbin/start-stop-daemon
    fi

    if [ -x "${ROOT_DIR}/sbin/initctl" ]; then
        echo "start-stop-daemon: Trying to prevent daemons from starting in ${ROOT_DIR}"

        # Disable initctl
        sudo mv "${ROOT_DIR}/sbin/initctl" "${ROOT_DIR}/sbin/initctl.REAL"
        sudo tee ${ROOT_DIR}/sbin/initctl > /dev/null <<-__EOF__
			#!/bin/sh
			echo
			echo "Warning: Fake initctl called, doing nothing"
		__EOF__

        sudo chmod 755 ${ROOT_DIR}/sbin/initctl
    fi

  	# Define sysvinit policy 101 to prevent daemons from starting in buildchroot
    if [ -x "${ROOT_DIR}/sbin/init" -a ! -f "${ROOT_DIR}/usr/sbin/policy-rc.d" ]; then
        echo "sysvinit: Using policy-rc.d to prevent daemons from starting in ${ROOT_DIR}"

        sudo tee ${ROOT_DIR}/usr/sbin/policy-rc.d > /dev/null <<-__EOF__
			#!/bin/sh
			echo "sysvinit: All runlevel operations denied by policy" >&2
			exit 101
		__EOF__
        sudo chmod a+x ${ROOT_DIR}/usr/sbin/policy-rc.d
    fi

    # Set hostname
    sudo sh -c 'echo "isar" > ${ROOT_DIR}/${sysconfdir}/hostname'

    # Install host networking settings
    sudo cp /${sysconfdir}/resolv.conf ${ROOT_DIR}/${sysconfdir}

    # Create deb folder for installing potential dependencies
    sudo install -m 0777 -d ${ROOT_DIR}${CHROOT_DEPLOY_DIR_DEB}

    # Replace directory of apt caches for using within chroots
    # Set the trusted=yes option for local unsigned cache repository.
    sudo sed -i -e 's|${CACHE_DIR}|${CHROOT_CACHE_DIR}|g' \
                -e 's|\[|\[ trusted=yes |g' \
        ${ROOT_DIR}/${sysconfdir}/apt/sources.list.d/multistrap-${DISTRO_CACHE_SECTION}.list
}
addtask do_setup_rootfs before do_configure_rootfs
do_setup_rootfs[stamp-extra-info] = "${DISTRO}"


do_configure_rootfs() {
    # Configure root filesystem
	cat<<-__EOF__ > /etc/default/locale
		LANG=en_US.UTF-8
		LANGUAGE=en_US.UTF-8
		LC_ALL=C
		LC_CTYPE=C
	__EOF__


    ## Configuration file for localepurge(8)
    cat<<-__EOF__ > /etc/locale.nopurge
		# Remove localized man pages
		MANDELETE

		# Delete new locales which appear on the system without bothering you
		DONTBOTHERNEWLOCALE

		# Keep these locales after package installations via apt-get(8)
		en
		en_US
		en_US.UTF-8
	__EOF__

    debconf-set-selections <<-__EOF__
		locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8
		locales locales/default_environment_locale select en_US.UTF-8
	__EOF__

    #set up non-interactive configuration
    export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
    export LC_ALL=C LANGUAGE=C LANG=C

    #run pre installation script
    /var/lib/dpkg/info/dash.preinst install

    #configuring packages
    dpkg --configure -a
    apt-get update
}
addtask do_configure_rootfs after do_setup_rootfs before do_install
do_configure_rootfs[stamp-extra-info] = "${DISTRO}.chroot"
do_configure_rootfs[chroot] = "1"
do_configure_rootfs[id] = "${CHROOT_ID}"


stage_packages() {
    sudo find . -name "*.deb" -exec mv '{}' $2 \;
}


do_install() {
    stage_packages ${ROOT_DIR} ${CACHE_STAGING_DIR}/
}
addtask do_install after do_configure_rootfs before do_build
do_install[lockfiles] = "${DPKG_LOCK}"
do_install[dirs] = "${CACHE_STAGING_DIR}"


do_build() {
    :
}


do_clean_append() {
    rootfs_dir = d.getVar('ROOT_DIR', True)
    checkmount(rootfs_dir)
    shell.call(['sudo', 'rm', '-rf', rootfs_dir])
}


do_cleanall_append() {
    rootfs_dir = d.getVar('ROOT_DIR', True)
    checkmount(rootfs_dir)
    shell.call(['sudo', 'rm', '-rf', rootfs_dir])
}