IMAGE_FSTYPES ?= "sdcard"
SUPPORTED_FSTYPES = "sdcard sdcard-redundant ext4"


python() {
    images_types_var = d.getVar('IMAGE_FSTYPES', True)
    supported_types  = d.getVar('SUPPORTED_FSTYPES', True)
    if len(images_types_var) == 0:
        d.setVar('IMAGE_TYPES_CREATE', '')
        return

    types = []
    for image in images_types_var.split():
        if image not in supported_types:
            bb.fatal('Image type %s not supported. Please add fstype to SUPPORTED_FSTYPES. Supported types: %s' % (image, supported_types))

        types.append(image)

    types = ' '.join(types)
    d.setVar('IMAGE_TYPES_CREATE', types)
}
