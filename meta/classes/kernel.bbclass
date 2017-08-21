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

DTB_SRC_DIR ?= "arch/${TARGET_ARCH}/boot/dts"
DTBS        ?= ""
DTB_DEST_DIR ?= "boot/dts"
KIMAGE_TYPE ?= "zImage"
UIMAGE_LOADADDR ?= ""

CROSS_COMPILE ?= ""
UIMAGE_LOADADDR ?= ""

MAKE = " make ARCH=${TARGET_ARCH} "
MAKE_append_class-cross = "CROSS_COMPILE=${TARGET_PREFIX}-"


python() {
	base_make = d.getVar('MAKE', True)
	dtbos = d.getVar('DTBOS', True)
	dtbs  = d.getVar('DTBS', True)

	if len(dtbos) != 0:
		make = base_make + ' ' + dtbos
		d.setVar('MAKE_DTBOS', make)
	else:
		d.setVar('MAKE_DTBOS', '')

	if len(dtbs) != 0:
		make = base_make + ' ' + dtbs
		d.setVar('MAKE_DTBS', make)
	else:
		d.setVar('MAKE_DTBS', '')

}

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

do_unpack_post() {
    mv ${EXTRACTDIR}/dts-${MACHINE} ${EXTRACTDIR}/dts
    mv ${EXTRACTDIR}/${MACHINE}_defconfig ${EXTRACTDIR}/defconfig
}
do_unpack[postfuncs] += "do_unpack_post"


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

do_pre_install_append(){
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
	${MAKE_DTBOS}
	${MAKE_DTBS}
}


debianize_install[target] = "install"
debianize_install[tdeps] = "build"
debianize_install() {
	@echo "Running install target."
	dh_testdir
	dh_testroot

	mkdir -p debian/${BPN}
	mkdir -p debian/${BPN}/${DTB_DEST_DIR}
	mkdir -p debian/${BPN}/${DTBO_DEST_DIR}

	${MAKE} modules_install INSTALL_MOD_PATH=debian/${BPN}

	install -m 0644 arch/${TARGET_ARCH}/boot/${KIMAGE_TYPE}      debian/${BPN}/boot/${KIMAGE_TYPE}
	install -m 0644 $(shell find ${DTB_SRC_DIR} -name "*.dtb")   debian/${BPN}/${DTB_DEST_DIR}  || true
	install -m 0644 $(shell find ${DTBO_SRC_DIR} -name "*.dtbo") debian/${BPN}/${DTBO_DEST_DIR} || true
}
