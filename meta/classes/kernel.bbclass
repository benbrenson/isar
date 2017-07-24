# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

# Class implementing common functionalities for compiling the kernel.
# The kernel has to be capable to compile device tree overlays with the '-@' option.
# See commit baa05fa for information how the kernels kconfig system gets capable of compiling device tree overlays.
# So basically three steps have to be done:
# 1. Get an overlay capable dtc
# 2. Overwrite the kernel dtc with the overlay capable one.
# 3. Modify the kernel makefiles for beeing capable of compiling overlays (see commit baa05fa of kernel repository).
# TODO: Maybe we should move the dt compilation into a seperate bbclass, to get independent from kernel dtc support?

export DTB_SRC_DIR ?= "arch/${TARGET_ARCH}/boot/dts"
export DTBS        ?= ""
export DTB_DEST_DIR ?= "boot/dts"
export KIMAGE_TYPE ?= "zImage"
export UIMAGE_LOADADDR ?= ""

MAKE = "\
${@bb.utils.contains('CROSS_COMPILE_ENABLED', \
                     'true', \
                     'make ARCH=${TARGET_ARCH} CROSS_COMPILE=${CROSS_COMPILE}', \
                     'make ARCH=${TARGET_ARCH}', \
                      d)} \
                     "

KERNEL_EXTRA_OPTS_append = "\
${@bb.utils.contains('KIMAGE_TYPE', \
                     'uImage', \
                     'LOADADDR=${UIMAGE_LOADADDR}', \
                     '', \
                     d)} \
                     "

SECTION = "kernel"
PRIORITY = "optional"
LICENSE  = "gpl"

do_patch() {
    cd ${S}
    patches=$(ls ../*.patch)

    for patch in ${patches}; do
        patch -p1 < ${patch}
    done
}
addtask do_patch after do_unpack before do_build

do_copy_defconfig(){
    cd ${S}
    cp ${EXTRACTDIR}/defconfig ${S}/.config
    ${MAKE} olddefconfig

    touch .scmversion

}
addtask do_copy_defconfig after do_patch before do_copy_device_tree

do_copy_device_tree() {
    cp -r ${EXTRACTDIR}/dts ${S}/arch/${TARGET_ARCH}/boot
}
addtask do_copy_device_tree after do_copy_device_tree before do_build

do_install_append(){
    install -m 0644 ${S}/arch/${TARGET_ARCH}/boot/${KIMAGE_TYPE} ${DEPLOY_DIR_IMAGE}
}
do_install[dirs] += "${DEPLOY_DIR_IMAGE}"



###                              ###
### debianize makefile functions ###
###                              ###

debianize_build[target] = "build"
debianize_build() {
	@echo "Running build target."
	${MAKE} olddefconfig
	${MAKE} -j${PARALLEL_MAKE} ${KIMAGE_TYPE} ${KERNEL_EXTRA_OPTS}
	${MAKE} modules
	${MAKE} ${DTBOS}
	${MAKE} ${DTBS}
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

	mkdir -p debian/${PN}
	mkdir -p debian/${PN}/${DTB_DEST_DIR}
	mkdir -p debian/${PN}/${DTBO_DEST_DIR}

	${MAKE} modules_install INSTALL_MOD_PATH=debian/${PN}

	install -m 0644 arch/${TARGET_ARCH}/boot/${KIMAGE_TYPE}      debian/${PN}/boot/${KIMAGE_TYPE}
	install -m 0644 $(shell find ${DTB_SRC_DIR} -name "*.dtb")   debian/${PN}/${DTB_DEST_DIR}
	install -m 0644 $(shell find ${DTBO_SRC_DIR} -name "*.dtbo") debian/${PN}/${DTBO_DEST_DIR}
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
	dh_shlibdeps
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