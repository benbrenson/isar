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
#DEB_DEPENDS  (Package runtime dependencies)
#PRIORITY     (Debian priority: optional, required, important, standard, extra)
#SECTION      (Debian section of this package: main, non-free, contrib, devel, doc, libs, admin, mail, net... etc.)
#URL          (Package repository url, also required for recipes)
#DEB_ARCH     (Target Architecture: amd64, armhf, armel ... etc.)
#DESCRIPTION  (See recipes description)
#LICENSE      (gpl, gpl2, gpl3, lgpl, lgpl2 lgpl3, artistic, apache, bsd, mit or custom)
#DEBEMAIL
#DEBFULLNAME

PACKAGE_NAME ?= "${PN}"
SOURCE_NAME  ?= "${PN}"
DEB_PKG      ?= "${PN}_${PV}"
DEB_VERSION  ?= "${PV}"
MAINTAINER   ?= "${DEB_FULLNAME} ${DEB_EMAIL}"
DEB_ARCH     ?= "${DISTRO_ARCH}"
DEB_DEPENDS  ?= ""
DEB_ORIG_SUFFIX ?= ".orig.tar.xz"
DEB_DEBIANIZED_SUFFIX ?= "-*.debian.tar.xz"

export DEBEMAIL    = "${DEB_EMAIL}"
export DEBFULLNAME = "${DEB_FULLNAME}"


# Functions for creating the debian/rules file
def do_mcreate(func, mfile, d):
    if d.getVar(func, False):
        bb.data.emit_func_make(func, mfile, d)


def create (filename, d):
    with open(filename, 'w') as mfile:
        mfile.write('#!/usr/bin/make -f')
        do_mcreate('debianize_build', mfile, d)
        do_mcreate('debianize_clean', mfile, d)
        do_mcreate('debianize_build-indep', mfile, d)
        do_mcreate('debianize_install', mfile, d)
        do_mcreate('debianize_binary-arch', mfile, d)
        do_mcreate('debianize_binary-indep', mfile, d)
        do_mcreate('debianize_binary', mfile, d)
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
    sed -i -e 's/##DEPENDS##/${DEB_DEPENDS}/g'       ${CONTROL}
    sed -i -e 's/##VERSION##/${DEB_VERSION}/g'       ${CONTROL}
}
addtask do_generate_debcontrol after do_test_vars before do_dh_make
do_generate_debcontrol[stamp-extra-info] = "${DISTRO}"


python do_generate_rules(){
    if d.getVar('GENERATE_RULES', True) != 'true':
        return

    import shutil
    workdir = d.getVar('EXTRACTDIR', True)
    makefile = os.path.join(workdir, 'rules.generated')
    create(makefile, d)
    shutil.copy(makefile, workdir + '/debian/rules')
}
addtask do_generate_rules after do_generate_debcontrol before do_dh_make
do_generate_rules[stamp-extra-info] = "${DISTRO}"


do_dh_make(){
    cd ${S}
    rm -f ${WORKDIR}/${DEB_PKG}${DEB_ORIG_SUFFIX}
    rm -f ${WORKDIR}/${DEB_PKG}${DEB_DEBIANIZED_SUFFIX}
    rm -rf ${S}/debian
    rm -f ${WORKDIR}/${DEB_PKG}-*.dsc

    dh_make -n --copyright ${LICENSE} -y --createorig --single -t ${EXTRACTDIR}/debian/ -p ${DEB_PKG}
}
addtask do_dh_make after do_generate_debcontrol before do_build
do_dh_make[stamp-extra-info] = "${DISTRO}"

