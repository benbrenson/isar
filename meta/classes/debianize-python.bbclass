# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

inherit debianize

DEB_DEPENDS += "python${PYTHON_VERSION}-setuptools"
DEB_RDEPENDS += "${python3:Depends}"

PYTHON_VERSION ?= "3"
DH_MAKE ?= "dh_make -n --copyright ${LICENSE} -y --createorig --python -t ${EXTRACTDIR}/debian/ -p ${DEB_PKG}"

debianize_build[target] = "build"
debianize_build() {
	@echo "Running build target."
	python${PYTHON_VERSION} setup.py build -j${PARALLEL_MAKE}
}


debianize_clean[target] = "clean"
debianize_clean() {
	@echo "Running clean target."
	rm -rf debian/${BPN}
	python${PYTHON_VERSION} setup.py clean --all
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
	python${PYTHON_VERSION} setup.py install --root debian/${BPN}/
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
