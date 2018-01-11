IMAGE_TYPES ?= "sdcard sdcard-redundant"
SUPPORTED_IMAGE_TYPES = "sdcard sdcard-redundant"
UPDATEABLE_FSTYPES ?= "ext2 ext3 ext4 vfat fat16 fat32"

python() {
    images_types_var = d.getVar('IMAGE_TYPES', True)
    supported_image_types  = d.getVar('SUPPORTED_IMAGE_TYPES', True)

    types = []
    for image in images_types_var.split():
        if image not in supported_image_types:
            bb.fatal('Image type %s not supported. Please add fstype to SUPPORTED_IMAGE_TYPES. Supported types: %s' % (image, supported_image_types))
}
