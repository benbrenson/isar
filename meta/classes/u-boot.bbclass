###                              ###
### debianize makefile functions ###
###                              ###

CROSS_COMPILE ?= ""

MAKE ?= "make ARCH=${TARGET_ARCH}"
MAKE_class-cross = "make ARCH=${TARGET_ARCH} CROSS_COMPILE=${TARGET_PREFIX}-"
GENERATE_BOOTSCRIPT ?= ""

DH_SHLIBDEPS="\
${@bb.utils.contains('CROSS_COMPILE_ENABLED', \
'true', \
'dh_shlibdeps -l/usr/arm-linux-gnueabihf/lib/', \
'dh_shlibdeps', \
d)} \
"

BOOT="${EXTRACTDIR}/${BOOTSCRIPT_SRC}"
BOOT_DEVICE_NAME ?= ""
BOOT_DEVICE_NAME_mmc = "mmc"
CMDLINE_ROOTDEV_PRIM_mmc = "${base_devdir}/${BOOT_DEVICE_LINUX}${ROOTP_PRIM_NUM}"
CMDLINE_ROOTDEV_SEC_mmc  = "${base_devdir}/${BOOT_DEVICE_LINUX}${ROOTP_SEC_NUM}"

BOOT_DEVICE_NAME_nand = ""
CMDLINE_ROOTDEV_PRIM_nand = ""
CMDLINE_ROOTDEV_SEC_nand  = ""


do_generate_bootscript() {
	[ -z ${GENERATE_BOOTSCRIPT} ] && return
    [ -z ${KERNEL_CMDLINE} ] && bbfatal "No Kernel cmdline specified. Please set KERNEL_CMDLINE variable."

    sed -i -e 's|##BOOT_DEVICE_NUM##|${BOOT_DEVICE_NUM}|g'   ${BOOT}
    sed -i -e 's|##BOOT_DEVICE_NAME##|${BOOT_DEVICE_NAME}|g' ${BOOT}
    sed -i -e 's|##BOOTP_PRIM_NUM##|${BOOTP_PRIM_NUM}|g'     ${BOOT}
    sed -i -e 's|##BOOTP_SEC_NUM##|${BOOTP_SEC_NUM}|g'       ${BOOT}
    sed -i -e 's|##CMDLINE_ROOTDEV_PRIM##|${CMDLINE_ROOTDEV_PRIM}|g' ${BOOT}
    sed -i -e 's|##CMDLINE_ROOTDEV_SEC##|${CMDLINE_ROOTDEV_SEC}|g'   ${BOOT}
    sed -i -e 's|##KERNEL_CMDLINE##|${KERNEL_CMDLINE}|g'     ${BOOT}
    sed -i -e 's|##DTBS##|${DTBS}|g'                         ${BOOT}

}
addtask do_generate_bootscript after do_patch before do_build


do_copy_defconfig(){
	cd ${S}
    cp ${EXTRACTDIR}/defconfig ${S}/.config
    ${MAKE} olddefconfig
}
addtask do_copy_defconfig after do_patch before do_build


debianize_build[target] = "build"
debianize_build() {
	@echo "Running build target."
	${MAKE} -j${PARALLEL_MAKE} all
	${MAKE} env
	./tools/mkimage -C none -A arm -T script -d ${PP}/${BOOTSCRIPT_SRC} ${BOOTSCRIPT}
}


debianize_clean[target] = "clean"
debianize_clean() {
	@echo "Running clean target."
	rm -rf debian/${BPN}
}

debianize_install[target] = "install"
debianize_install[tdeps] = "build"
debianize_install() {
	@echo "Running install target."
	dh_testdir
	dh_testroot
	dh_clean  -k

	install -d debian/${BPN}/boot
	install -d debian/tmp

	install -m 0644 ${PPS}/${BOOT_IMG} debian/${BPN}/boot/${BOOT_IMG}
	[ -f ${PPS}/cmdline.txt ] && install -m 0644 ${PPS}/cmdline.txt debian/${BPN}/boot/cmdline.txt || echo "No cmdline.txt available...skipping."
	install -m 0644 ${BOOTSCRIPT} debian/${BPN}/boot/${BOOTSCRIPT}
	install -m 0644 tools/env/lib.a debian/tmp/libubootenv.a
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
