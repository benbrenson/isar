# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

# Class implementing common functionalities for compiling the kernel.
# The kernel has to be capable to compile device tree overlays with the '-@' option.
# So basically three steps have to be done:
# 1. Get an overlay capable dtc
# 2. Overwrite the kernel dtc with the overlay capable one.
# 3. Modify the kernel makefiles for beeing capable of compiling overlays (see commit baa05fa of kernel repository).

PROVIDES_append = " virtual/kernel "

DTB_SRC_DIR ?= "arch/${TARGET_ARCH}/boot/dts"
DTBS        ?= ""
DTB_DEST_DIR ?= "boot/dts"
KIMAGE_TYPE ?= "zImage"
UIMAGE_LOADADDR ?= ""

DTBO_SRC_DIR  ?= "arch/${TARGET_ARCH}/boot/dts/overlays"
DTBOS         ?= ""
DTBOS_LOAD    ?= ""
DTBO_DEST_DIR ?= "boot/dts/overlays"


CROSS_COMPILE ?= ""
UIMAGE_LOADADDR ?= ""

MAKE = " make ARCH=${TARGET_ARCH} "
MAKE_append_class-cross = "CROSS_COMPILE=${TARGET_PREFIX}-"

# Generate make command for dtbs and dtbos
python() {
	base_make = d.getVar('MAKE', True)
	dtbos = d.getVar('DTBOS', True) or ""
	dtbs  = d.getVar('DTBS', True) or ""

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

do_copy_defconfig(){
    cd ${S}
    cp ${EXTRACTDIR}/${MACHINE}_defconfig ${S}/.config
    ${MAKE} olddefconfig

    touch .scmversion

}
addtask do_copy_defconfig after do_patch before do_build

FIX_KVERSION ?= ""
do_generate_postinst() {
    if [ -z ${FIX_KVERSION} ]; then
        cd ${S}
        main_kversion="$(make kernelversion)"
        local_kversion="$(sed -n -e 's|CONFIG_LOCALVERSION="\(.*\)"|\1|p' ${S}/.config)"
        kversion="$main_kversion$local_kversion"
    else
        kversion="${FIX_KVERSION}"
    fi

    sed -i -e "s|##KVERSION##|$kversion|g" ${EXTRACTDIR}/debian/postinst
}
addtask do_generate_postinst after do_copy_defconfig before do_generate_debcontrol

do_install_append(){
    install -m 0644 ${S}/arch/${TARGET_ARCH}/boot/${KIMAGE_TYPE} ${DEPLOY_DIR_IMAGE}
    install -m 0644 ${S}/arch/${TARGET_ARCH}/boot/dts/${DTBS} ${DEPLOY_DIR_IMAGE}
}


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
