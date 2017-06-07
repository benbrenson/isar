# Class containing common functionalities for building debian
# based image with multistrap.
# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH
# Copyright (C) 2017 Mixed-Mode GmbH


DEPENDS += "${IMAGE_INSTALL}"

WORKDIR ?= "${TMPDIR}/work/${PN}/${MACHINE}"
S       ?= "${WORKDIR}/rootfs"


KERNEL_IMAGE ?= ""
INITRD_IMAGE ?= ""

IMAGE_INSTALL ?= ""
IMAGE_TYPES    ?= "ext4 sd-card tar.gz"

inherit image_types

do_populate[stamp-extra-info] = "${MACHINE}"

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
do_populate[deptask] = "do_install"


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
    sed -i 's|##CONFIG_SCRIPT##|./tmp/work/${PN}/${MACHINE}/configscript.sh|' ${WORKDIR}/multistrap.conf
    sed -i 's|##SETUP_SCRIPT##|./tmp/work/${PN}/${MACHINE}/setup.sh|' ${WORKDIR}/multistrap.conf

    # Multistrap config use relative paths, so ensure that we are in the right folder
    cd ${TOPDIR}

    # Create root filesystem
    sudo multistrap -a ${DISTRO_ARCH} -d "${S}" -f "${WORKDIR}/multistrap.conf" || true

    # Configure root filesystem
    sudo chroot ${S} /configscript.sh ${MACHINE_SERIAL}
    sudo rm ${S}/configscript.sh
}
do_rootfs[stamp-extra-info] = "${MACHINE}"
addtask rootfs before do_populate