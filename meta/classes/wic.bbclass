# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH


WIC_DEBUG = "-D"
WICVARS ?= "BUILDCHROOT_DIR BBLAYERS DEPLOY_DIR_IMAGE HDDDIR IMAGE_BASENAME IMAGE_BOOT_FILES IMAGE_LINK_NAME BOOT_IMG KIMAGE_TYPE ROOTFS_DIR INITRAMFS_FSTYPES INITRD ISODIR MACHINE_ARCH ROOTFS_SIZE STAGING_DATADIR STAGING_DIR_NATIVE STAGING_LIBDIR TARGET_SYS"
WICVARS_DIR = "${TOPDIR}"
IMAGE_PART_DESC ?= "${THISDIR}/files/isar-image-base.wks"

python do_emit_wicvars() {
    """
    Write environment variables used by wic
    """
    basedir  = d.getVar('WICVARS_DIR', True)
    basename = d.getVar('PN', True)
    with open(os.path.join(basedir, basename) + '.env', 'w') as envf:
        for var in d.getVar('WICVARS', True).split():
            value = d.getVar(var, True)
            if value:
                envf.write('%s="%s"\n' % (var, value.strip()))
}
addtask do_emit_wicvars after do_post_rootfs before do_image
do_emit_wicvars[stamp-extra-info] = "${MACHINE}"

do_image(){

    ${SUDO} -- wic create -o ${DEPLOY_DIR_IMAGE} \
               -v ${WICVARS_DIR} \
               -e ${PN} \
               ${WIC_DEBUG} \
               --rootfs-dir rootfs1=${ROOTFS_DIR} \
               --rootfs-dir rootfs2=${ROOTFS_DIR}  \
               ${IMAGE_PART_DESC}
}
addtask do_image after do_emit_wicvars before do_build
do_image[stamp-extra-info] = "${MACHINE}"