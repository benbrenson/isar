# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

inherit debianize

PYTHON_VERSION ?= ""
DEB_DEPENDS += "python3-wheel"
DEB_RDEPENDS += "${python3:Depends}"

DEB_ARCH_CTRL="all"


#
# Install python package dependencies with pip
#
do_install_depends_pip() {
	cd ${PPS}
	if [ -e "setup.py" ]; then
		pip${PYTHON_VERSION} install -I --root ${PPS}/debian/${BPN} -e .
	fi
}
addtask do_install_depends_pip after do_install_depends before do_build
do_install_depends_pip[stamp-extra-info] = "${MACHINE}.chroot"
do_install_depends_pip[id] = "${BUILDCHROOT_ID}"
do_install_depends_pip[chroot] = "1"



debianize_build[target] = "build"
debianize_build() {
	@echo "Running build target."
	python${PYTHON_VERSION} setup.py build
}


debianize_install[target] = "install"
debianize_install[tdeps] = "build"
debianize_install() {
	@echo "Running install target."
	dh_testdir
	dh_testroot
	python${PYTHON_VERSION} setup.py install --root ${PPS}/debian/${BPN}/
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
