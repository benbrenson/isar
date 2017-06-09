# This software is a part of ISAR.
# Copyright (C) 2017 Mixed-Mode GmbH
#
# This class provides common functionalities to modify
# software packages to be debian compatible.
# Please make sure you have already created a rules and control file for your package,
# which resides at the recipes' file folder (<path_to_recipe>/files/debian/[rules,control]).

#Variables
#PACKAGE_NAME (Name of the binary package build from source package)
#SOURCE_NAME  (Name of the debianized source package, this has to be the basename of PACKAGE_NAME, since each package will be build from source package)
#DEB_DEPENDS  (Package runtime dependencies)
#PRIORITY     (Debian priority: optional, required, important, standard, extra)
#SECTION      (Debian section of this package: main, non-free, contrib, devel, doc, libs, admin, mail, net... etc.)
#URL          (Package repository url, also required for recipes)
#DEB_ARCH     (Target Architecture: amd64, armhf, armel ... etc.)
#DESCRIPTION  (See recipes description)
#LICENSE
#DEBEMAIL
#DEBFULLNAME

PACKAGE_NAME ?= "${PN}"
SOURCE_NAME  ?= "${PN}"
DEB_PKG      ?= "${PN}_${PV}"
DEB_VERSION  ?= "${PV}"
MAINTAINER   ?= "${DEB_FULLNAME} ${DEB_EMAIL}"
DEB_DEPENDS  ?= ""
DEB_ORIG_SUFFIX ?= ".orig.tar.xz"
DEB_DEBIANIZED_SUFFIX ?= "-*.debian.tar.xz"

export DEBEMAIL    = "${DEB_EMAIL}"
export DEBFULLNAME = "${DEB_FULLNAME}"


def test_var(d, varname):
    var = d.getVar(varname, True)
    #bb.warn("Testing Var: {0}. Value:{1}".format(varname, var))

    if not var or len(var) == 0:
        bb.fatal('Variable "{}" must be defined.'.format(varname))


# Test at parser time if all required variables where set
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

