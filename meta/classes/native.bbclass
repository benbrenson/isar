# This software is a part of ISAR.
# Copyright (C) 2017 Mixed-Mode GmbH

DEPENDS += "cross-buildchroot"

OVERRIDES .= ":class-native"

CHROOT_DIR = "${CROSS_BUILDCHROOT_DIR}"
BUILDROOT = "${CHROOT_DIR}/${PP}"
EXTRACTDIR = "${BUILDROOT}"
S = "${EXTRACTDIR}/${SRC_DIR}"

DEB_ARCH = "${DEB_HOST_ARCH}"

# Set chroot environment for do build and do_install task
do_install_depends[id] = "${CROSS_BUILDCHROOT_ID}"
do_build[id] = "${CROSS_BUILDCHROOT_ID}"
do_install[id] = "${CROSS_BUILDCHROOT_ID}"


# Create a new version for RPROVIDES, PROVIDES, DEB_DEPENDS and DEB_RDEPENDS with '-native' suffix appended
# to all packages.
SKIP_APPEND_NATIVE_SUFFIX ?= ""
python() {
    import oe.utils

    # Skip values starting with:
    skip = 'virtual/ ${ debhelper ' + d.getVar('SKIP_APPEND_NATIVE_SUFFIX', True)

    provides = d.getVar('PROVIDES', True)
    new = oe.utils.append_suffixes(provides, '-native', skip, d)
    d.setVar('PROVIDES', new)

    provides = d.getVar('RPROVIDES', True)
    new = oe.utils.append_suffixes(provides, '-native', skip, d)
    d.setVar('RPROVIDES', new)

    deb_depends = d.getVar('DEB_DEPENDS', True)
    new = oe.utils.append_suffixes(deb_depends, '-native', skip, d)
    d.setVar('DEB_DEPENDS', new)

    deb_rdepends = d.getVar('DEB_RDEPENDS', True)
    new = oe.utils.append_suffixes(deb_rdepends, '-native', skip, d)
    d.setVar('DEB_RDEPENDS', new)
}

