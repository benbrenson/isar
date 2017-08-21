# This software is a part of ISAR.
# Copyright (C) 2017 Mixed-Mode GmbH
#
# This class provides common functionalities to modify
# software packages to be debian compatible.
# Please make sure you have already created a rules and control file for your package,
# which resides at the recipes' file folder (<path_to_recipe>/files/debian/[rules,control]).
# Instead of providing a rules file, it is also possible to define all required debianized_* tasks
# as bitbake shell tasks. The makefile generator will then generate a debian rules file with rules consisting of
# the defined bitbake shell tasks.

#Variables
#PACKAGE_NAME (Name of the binary package build from source package)
#SOURCE_NAME  (Name of the debianized source package, this has to be the basename of PACKAGE_NAME, since each package will be build from source package)
#DEB_DEPENDS  (Source package build dependencies)
#DEB_RDEPENDS (Binary package runtime dependencies)
#DEB_RDEPENDS_DEV (Binary dev-package runtime dependencies)
#DEB_RDEPENDS_DBG (Binary dbg-package runtime dependencies)
#DEPENDS_VARS (Collection of all DEPENDS vars, required for extending vars in recipes)
#PRIORITY     (Debian priority: optional, required, important, standard, extra)
#SECTION      (Debian section of this package: main, non-free, contrib, devel, doc, libs, admin, mail, net... etc.)
#URL          (Package repository url, also required for recipes)
#DEB_ARCH     (Target Architecture: amd64, armhf, armel ... etc.)
#DESCRIPTION  (See recipes description)
#LICENSE      (gpl, gpl2, gpl3, lgpl, lgpl2 lgpl3, artistic, apache, bsd, mit or custom)
#DEBEMAIL
#DEBFULLNAME

PACKAGE_NAME ?= "${BPN}"
SOURCE_NAME  ?= "${BPN}"
DEB_PKG      ?= "${BPN}_${PV}"
DEB_VERSION  ?= "${PV}"
MAINTAINER   ?= "${DEB_FULLNAME} ${DEB_EMAIL}"
DEB_ARCH     ?= "${DISTRO_ARCH}"
DEB_DEPENDS  ?= "debhelper:(>=9) "
DEB_RDEPENDS ?= "${shlibs:Depends} ${misc:Depends} "
DEB_RDEPENDS_DEV ?= "${shlibs:Depends} ${misc:Depends} "

RDEPENDS_VARS = " DEB_RDEPENDS DEB_RDEPENDS_DEV RDEPENDS"
BUILD_DEPENDS_VARS = " DEB_DEPENDS DEPENDS"
DEPENDS_VARS = "${BUILD_DEPENDS_VARS} ${RDEPENDS_VARS} "

# Skipp these variables when generating debian dependencies
# since they are no debian package based dependencies
SKIPP_DEPENDS = "buildchroot cross-buildchroot"

# What we do here is to concentate the fixed DEP strings (e.g. DEPENDS="bar foo" -> DEPENDS_FIXED="bar, foo, ")
# into a new variable which then will substitute the Build depends variable in control file.
# We won't make use use of the original DEP vars, since changing them may break bitbakes dependency chain.
DEPS_FIXED = ""
RDEPS_FIXED = ""

DEB_ORIG_SUFFIX ?= ".orig.tar.xz"
DEB_DEBIANIZED_SUFFIX ?= "-*.debian.tar.xz"

export DEBEMAIL    = "${DEB_EMAIL}"
export DEBFULLNAME = "${DEB_FULLNAME}"


# Functions for creating the debian/rules file
def do_mcreate(func, mfile, d):
    if d.getVar(func, False):
        bb.data.emit_func_make(func, mfile, d)


def create (filename, d):
    keys = []
    for key in bb.data.keys(d):
        if 'debianize_' in key:
            keys.append(key)

    if not len(keys):
        bb.warn('No debianize_* function defined. Skipping...')
        return

    with open(filename, 'w') as mfile:
        mfile.write('#!/usr/bin/make -f\n')
        mfile.write('DH_VERBOSE=1')

        for deb in keys:
            do_mcreate(deb, mfile, d)

        mfile.write('\n .PHONY: build clean binary-indep binary-arch binary install \n')


def test_var(d, varname):
    var = d.getVar(varname, True)

    if not var or len(var) == 0:
        bb.fatal('Variable "{}" must be defined.'.format(varname))


# Test if all required variables where set
python do_test_vars () {
    test_var(d, 'PACKAGE_NAME')
    test_var(d, 'SOURCE_NAME')
    test_var(d, 'PRIORITY')
    test_var(d, 'SECTION')
    test_var(d, 'URL')
    test_var(d, 'DEB_ARCH')
    test_var(d, 'DESCRIPTION')
    test_var(d, 'LICENSE')
    test_var(d, 'DEB_EMAIL')
    test_var(d, 'DEB_FULLNAME')
}
addtask do_test_vars after do_unpack before do_generate_debcontrol
do_test_vars[stamp-extra-info] = "${DISTRO}"


# Generate Build-Depends and Depends for debian control
python do_deb_depends() {

    vars          = d.getVar('DEPENDS_VARS', True)
    deb_host_arch = d.getVar('DEB_HOST_ARCH', True)
    distro_arch   = d.getVar('DISTRO_ARCH', True)
    skipps        = d.getVar('SKIPP_DEPENDS', True)
    build_depends = ''
    rdepends      = ''

    for var in vars.split():
        depends = bb.utils.rmDupVar(d, var)
        depends = depends.split()

        # Try to clean depends from possible skipp value, since
        # these depends are no debian packages.
        # Do this silently!
        for skipp in skipps.split():
            try:
                depends.remove(skipp)
            except ValueError:
                pass

        if not len(depends):
            continue

        for i in range(len(depends)):
            # Skipp ${*:*} similiar vars
            if depends[i].startswith('$'):
                continue
            depends[i] = depends[i].replace(':',' ')

            # Exchange -native suffix with DEB_HOST_ARCH and
            # -cross suffix with DISTRO_ARCH
            if depends[i].endswith('-native'):
                depends[i] = depends[i].replace('-native', ':' + deb_host_arch)
            if depends[i].endswith('-cross'):
                depends[i] = depends[i].replace('-cross', ':' + distro_arch)

        # Now concentate fixed strings
        # TODO:
        # Each 'Depends' variable collects all rdepends based variables
        # Need to distinguish between different package types, and
        # distribute associated variables.
        if var in d.getVar('BUILD_DEPENDS_VARS', True).split():
            build_depends += ', '.join(depends)
            build_depends += ', '
        if var in d.getVar('RDEPENDS_VARS', True).split():
            rdepends += ', '.join(depends)
            rdepends += ', '

    build_depends = bb.utils.rmDupString(build_depends, ',')
    rdepends = bb.utils.rmDupString(rdepends, ',')

    # Now concentate DEPENDS and RDEPENDS and DEB_DEPENDS into DEPS_FIXED
    d.setVar('DEPS_FIXED', build_depends)
    d.setVar('RDEPS_FIXED', rdepends)
}


CONTROL="${EXTRACTDIR}/debian/control"
do_generate_debcontrol() {

    sed -i -e 's/##PACKAGE##/${PACKAGE_NAME}/g'      ${CONTROL}
    sed -i -e 's/##PACKAGE_BASE##/${SOURCE_NAME}/g'  ${CONTROL}
    sed -i -e 's/##SECTION##/${SECTION}/g'           ${CONTROL}
    sed -i -e 's/##PRIORITY##/${PRIORITY}/g'         ${CONTROL}
    sed -i -e 's|##URL##|${URL}|g'                   ${CONTROL}
    sed -i -e 's/##DEB_ARCH##/${DEB_ARCH}/g'         ${CONTROL}
    sed -i -e 's/##DESCRIPTION##/${DESCRIPTION}/g'   ${CONTROL}
    sed -i -e 's/##MAINTAINER##/${MAINTAINER}/g'     ${CONTROL}
    sed -i -e 's/##DEPENDS##/${DEPS_FIXED}/g'        ${CONTROL}
    sed -i -e 's/##VERSION##/${DEB_VERSION}/g'       ${CONTROL}
    sed -i -e 's/##RDEPENDS##/${RDEPS_FIXED}/g'      ${CONTROL}
}
addtask do_generate_debcontrol after do_test_vars before do_dh_make
do_generate_debcontrol[stamp-extra-info] = "${DISTRO}"
do_generate_debcontrol[prefuncs] = "do_deb_depends"


python do_generate_rules(){
    rules_exist = d.getVar('RULE_EXIST', True) or "false"
    if rules_exist == 'true':
        return

    import shutil
    workdir = d.getVar('EXTRACTDIR', True)
    makefile = os.path.join(workdir, 'rules.generated')
    create(makefile, d)
    shutil.copy(makefile, workdir + '/debian/rules')
}
addtask do_generate_rules after do_generate_debcontrol before do_dh_make
do_generate_rules[stamp-extra-info] = "${DISTRO}"

DH_MAKE ?= "dh_make -n --copyright ${LICENSE} -y --createorig --single -t ${EXTRACTDIR}/debian/ -p ${DEB_PKG}"
do_dh_make(){
    cd ${S}

    rm -f ${BUILDROOT}/${DEB_PKG}${DEB_ORIG_SUFFIX}
    rm -f ${BUILDROOT}/${DEB_PKG}${DEB_DEBIANIZED_SUFFIX}
    rm -rf ${S}/debian
    rm -f ${BUILDROOT}/${DEB_PKG}-*.dsc

    ${DH_MAKE}
}
addtask do_dh_make after do_generate_rules before do_build
do_dh_make[stamp-extra-info] = "${DISTRO}"




###                              ###
### debianize makefile functions ###
###                              ###
debianize_build[target] = "build"
debianize_build() {
	@echo "Running build target."
}


debianize_clean[target] = "clean"
debianize_clean() {
	@echo "Running clean target."
}


debianize_build-arch[target] = "build-arch"
debianize_build-arch() {
	@echo "Running build-arch target."
}


debianize_build-indep[target] = "build-indep"
debianize_build-indep() {
	@echo "Running build-indep target."
}


debianize_install[target] = "install"
debianize_install[tdeps] = "build"
debianize_install() {
	@echo "Running install target."
	dh_testdir
	dh_testroot
	dh_clean  -k
}



debianize_binary-arch[target] = "binary-arch"
debianize_binary-arch[tdeps] = "build install"
debianize_binary-arch() {
	@echo "Running binary-arch target."
	dh_testdir
	dh_testroot
	dh_installchangelogs
	dh_installdocs
	dh_installexamples
	dh_install
	dh_installman
	dh_link
	dh_strip
	dh_compress
	dh_fixperms
	dh_installdeb
	dh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info
	dh_gencontrol
	dh_md5sums
	dh_builddeb
}


debianize_binary-indep[target] = "binary-indep"
debianize_binary-indep[tdeps] = "build install"
debianize_binary-indep() {
	@echo "Running binary-indep target."
}


debianize_binary[target] = "binary"
debianize_binary[tdeps] = "binary-arch binary-indep"
debianize_binary() {
	@echo "Running binary target."
}

#EXPORT_FUNCTIONS debianize_build debianize_clean debianize_build-arch debianize_build-indep debianize_install debianize_binary-arch debianize_binary-indep debianize_binary