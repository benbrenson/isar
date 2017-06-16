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

SRC_DIR ?= "git"

export DTB_SRC_DIR ?= "arch/${CCARCH}/boot/dts"
export DTBS        ?= ""
export DTB_INSTALL_DIR_BASE ?= "boot"
export DTB_INSTALL_DIR ?= "${DTB_INSTALL_DIR_BASE}/dts"
export KIMAGE_TYPE ?= "zImage"
export UIMAGE_LOADADDR ?= ""

MAKE="make ARCH=${CCARCH} CROSS_COMPILE=${CROSS_COMPILE}"
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
