# This software is a part of Isar.
# Copyright (C) 2024 ilbers GmbH

inherit dpkg-raw

PN:append = "-${MACHINE}"

KERNEL_IMAGE_PKG ??= "${@ ("linux-image-" + d.getVar("KERNEL_NAME")) if d.getVar("KERNEL_NAME") else ""}"

DEPENDS = "${KERNEL_IMAGE_PKG}"
DEBIAN_BUILD_DEPENDS = "${KERNEL_IMAGE_PKG}"

do_prepare_build:prepend() {
    mkdir -p ${D}/usr/lib/${PN}
}

do_prepare_build:append() {
    cat <<EOF >> ${S}/debian/rules

override_dh_auto_build:
EOF
    for dtb in ${DTB_FILES}; do
        mkdir -p ${D}/usr/lib/${PN}/$(dirname ${dtb})
        ppdir=${PP}/image/usr/lib/${PN}/$(dirname ${dtb})
        cat <<EOF >> ${S}/debian/rules
	find /usr/lib/linux-image* -path "*${dtb}" -print -exec cp {} ${ppdir} \;
EOF
    done
}

DTB_PACKAGE ??= "${PN}_${CHANGELOG_V}_${DISTRO_ARCH}.deb"

do_deploy[dirs] = "${DEPLOY_DIR_IMAGE}"
do_deploy[cleandirs] = "${WORKDIR}/deploy"
do_deploy() {
    dpkg --fsys-tarfile ${WORKDIR}/${DTB_PACKAGE} | \
    tar --wildcards --extract --directory ${WORKDIR}/deploy ./usr/lib/${PN}
    for dtb in ${DTB_FILES}; do
        mkdir -p ${DEPLOY_DIR_IMAGE}/$(dirname ${dtb})
        find ${WORKDIR}/deploy/usr/lib/${PN} -path "*${dtb}" -print \
            -exec cp {} ${DEPLOY_DIR_IMAGE}/${dtb} \;
    done
}

addtask deploy before do_deploy_deb after do_dpkg_build
