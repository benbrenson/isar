# Class implementing common functionalities for compiling the kernel.
# The kernel has to be capable to compile device tree overlays with the '-@' option.
# See commit baa05fa for information how the kernels kconfig system gets capable of compiling device tree overlays.
# So basically three steps have to be done:
# 1. Get an overlay capable dtc
# 2. Overwrite the kernel dtc with the overlay capable one.
# 3. Modify the kernel makefiles for beeing capable of compiling overlays (see commit baa05fa of kernel repository).
# TODO: Maybe we should move the dt compilation into a seperate bbclass, to get independent from kernel dtc support?

DTB_DIR   ?= "dts"
DTBO_DIR  ?= "dts/overlays"
DTB_DEST  ?="${B}/${DTB_DIR}"
DTBO_DEST ?="${B}/${DTBO_DIR}"
MAKE="make ARCH=${CCARCH} CROSS_COMPILE=${CROSS_COMPILE}"

SRC_DIR="git"
IMAGE_TYPE="${@bb.utils.contains('KIMAGE_TYPE', 'uImage', '--uimage', '', d)}"

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
    cp ${WORKDIR}/defconfig ${S}/.config
    sudo make ARCH=${CCARCH} olddefconfig

}
addtask do_copy_defconfig after do_patch before do_build

do_prepare_deb() {
    cd ${S}

    ${SUDO} LOADADDR=${UIMAGE_LOADADDR} \
          CONCURRENCY_LEVEL=${PARALLEL_MAKE} \
          make-kpkg \
          --arch ${DEB_ARCH} \
          --cross-compile ${CROSS_COMPILE} \
          ${IMAGE_TYPE} \
          --revision=${KVERSION} \
          --overlay-dir ${WORKDIR}/debianize \
          debian
}
addtask do_prepare_deb after do_copy_defconfig before do_build
do_prepare_deb[deptask] = "do_install"


do_update_dtc() {
    cd ${S}

    # We need to compile the standart dtc first, since copying the modified dtc
    # is not enough. The dtc otherwise will be recompiled again.
    ${SUDO} ${MAKE} scripts
    ${SUDO} cp ${TOOLSDIR_NATIVE}/dtc/dtc ${S}/scripts/dtc
}
do_update_dtc[depends] = "dtc:do_install"
addtask do_update_dtc after do_prepare_deb before do_build


do_copy_device_tree() {
    ${SUDO} cp -r ${WORKDIR}/dts ${S}/arch/arm/boot
}
addtask do_copy_device_tree after do_update_dtc before do_build


do_compile_dtb() {
    cd ${S}
    for dtb in ${DTBS}; do
        ${SUDO} ${MAKE} ${dtb}
    done

}
addtask do_compile_dtb after do_copy_device_tree before do_build

# Install device trees into the debian package directory.
do_install_dtb() {
    for dtb in ${DTBS}; do
        ${SUDO} cp ${S}/arch/arm/boot/dts/${dtb} ${DTB_DEST}
    done
}
do_install_dtb[dirs] += "${DTB_DEST}"
addtask do_install_dtb after do_compile_dtb before do_build


do_compile_overlays() {
    cd ${S}
    for dtbo in ${DTBOS}; do
        ${SUDO} ${MAKE} ${dtbo}
    done
}
addtask do_compile_overlays after do_install_dtb before do_build


# Install overlays into the debian package directory.
do_install_overlays() {
    for dtbo in ${DTBOS}; do
        ${SUDO} cp ${S}/arch/arm/boot/dts/overlays/${dtbo} ${DTBO_DEST}
    done
}
do_install_overlays[dirs] += "${DTBO_DEST}"
addtask do_install_overlays after do_compile_overlays before do_build


# Now after device tree files where compiled and added to the debian package
# we can build the kernel package
do_build() {
    cd ${S}
    ${SUDO}  DTB_DIR=${DTB_DIR} \
          DTBO_DIR=${DTBO_DIR} \
          DTB_DEST=${DTB_DEST} \
          DTBO_DEST=${DTBO_DEST} \
          LOADADDR=${UIMAGE_LOADADDR} \
          CONCURRENCY_LEVEL=8 \
          make-kpkg \
          --arch ${DEB_ARCH} \
          --cross-compile ${CROSS_COMPILE} \
          ${IMAGE_TYPE} \
          --revision=${KVERSION} \
          --overlay-dir ${WORKDIR}/debianize \
          ${TARGET}

          mv ${WORKDIR}/*.deb ${B}
}

do_install() {
    install -m 0755 ${B}/linux-image-*_${KVERSION}_${DEB_ARCH}.deb ${DEPLOY_DIR_DEB}/${PROVIDES}_${KVERSION}_${DEB_ARCH}.deb
}