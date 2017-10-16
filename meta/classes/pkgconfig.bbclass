# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

# Default path where pkgconfig files residing
PKG_CONFIG_DIR ?= "${S}/pkgconfig/*"

# Fixup path of 'prefix' wrongly pointing to
# debian directory.
python do_fixup_pkgconfig() {
    import oe.pkgconfig

    location = d.getVar('PKG_CONFIG_DIR', True)
    fixed_prefix = d.getVar('prefix', True) or ""

    oe.pkgconfig.fixVar('prefix' , fixed_prefix, location, d)
}
addtask do_fixup_pkgconfig after do_patch before do_build