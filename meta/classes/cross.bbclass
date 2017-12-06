# This software is a part of ISAR.
# Copyright (C) 2017 Mixed-Mode GmbH

inherit dpkg-cross

FILESPATH_prepend := "${THISDIR}/${BPN}:${THISDIR}/${BPN}-${PV}:${THISDIR}/${BPN}-${PV}-${PR}:"
OVERRIDES .= ":class-cross"

CROSS_COMPILE="${TARGET_PREFIX}"
CCARCH="${TARGET_ARCH}"
ARCH="${TARGET_ARCH}"

# Create a new version for RPROVIDES, PROVIDES, DEB_DEPENDS and DEB_RDEPENDS with '-cross' suffix appended
# to all packages.
python() {
    import oe.utils

    skipp = 'virtual/ ${'

    provides = d.getVar('PROVIDES', True)
    new = oe.utils.append_suffixes(provides, '-cross', skipp, d)
    d.setVar('PROVIDES', new)

    provides = d.getVar('RPROVIDES', True)
    new = oe.utils.append_suffixes(provides, '-cross', skipp, d)
    d.setVar('RPROVIDES', new)

    deb_depends = d.getVar('DEB_DEPENDS', True)
    new = oe.utils.append_suffixes(deb_depends, '-cross', skipp, d)
    #d.setVar('DEB_DEPENDS', new)

    deb_rdepends = d.getVar('DEB_RDEPENDS', True)
    new = oe.utils.append_suffixes(deb_rdepends, '-cross', skipp, d)
    d.setVar('DEB_RDEPENDS', new)
}
