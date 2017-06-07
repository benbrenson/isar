# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

inherit fetch

# Add dependency from buildchroot creation
DEPENDS += "buildchroot"
do_unpack[deptask] = "do_build"

# Each package should have its own unique build folder, so use
# recipe name as identifier
PP = "/home/builder/${PN}"
BUILDROOT = "${BUILDCHROOT_DIR}/${PP}"

EXTRACTDIR="${BUILDROOT}"
S = "${BUILDROOT}/${SRC_DIR}"

python () {
    s = d.getVar('S', True).rstrip('/')
    extract_dir = d.getVar('EXTRACTDIR', True).rstrip('/')

    if s == extract_dir:
        bb.fatal('\nS equals EXTRACTDIR. Maybe SRC_DIR variable was not set.')
}

# Build package from sources using build script
do_build() {
    sudo chroot ${BUILDCHROOT_DIR} /build.sh ${PP}/${SRC_DIR}
}

do_install[stamp-extra-info] = "${MACHINE}"

# Install package to dedicated deploy directory
do_install() {
    install -d ${DEPLOY_DIR_DEB}
    install -m 755 ${BUILDROOT}/*.deb ${DEPLOY_DIR_DEB}/
}

addtask do_install after do_build
