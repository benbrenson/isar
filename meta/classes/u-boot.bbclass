###                              ###
### debianize makefile functions ###
###                              ###

MAKE = "\
${@bb.utils.contains('CROSS_COMPILE_ENABLED', \
'true', \
'make ARCH=${TARGET_ARCH} CROSS_COMPILE=${CROSS_COMPILE}', \
'make ARCH=${TARGET_ARCH}', \
d)} \
"

DH_SHLIBDEPS="\
${@bb.utils.contains('CROSS_COMPILE_ENABLED', \
'true', \
'dh_shlibdeps -l${ROOTFS_DIR}/lib/arm-linux-gnueabihf/', \
'dh_shlibdeps', \
d)} \
"

debianize_build[target] = "build"
debianize_build() {
	@echo "Running build target."
	cp ${EXTRACTDIR}/defconfig .config
	${MAKE} olddefconfig
	${MAKE} -j${PARALLEL_MAKE} all
	./tools/mkimage -C none -A arm -T script -d ${EXTRACTDIR}/${BOOTSCRIPT_SRC} ${BOOTSCRIPT}
}

debianize_clean[target] = "clean"
debianize_clean() {
	@echo "Running clean target."
	${MAKE} mrproper
	rm -rf debian/${PN}
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

	install -d debian/${PN}/boot
	install -m 0644 ${S}/${BOOT_IMG} debian/${PN}/boot/${BOOT_IMG}
	install -m 0644 ${S}/cmdline.txt debian/${PN}/boot/cmdline.txt
	install -m 0644 boot.scr debian/${PN}/boot/${BOOTSCRIPT}
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
	${DH_SHLIBDEPS} --dpkg-shlibdeps-params=--ignore-missing-info
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