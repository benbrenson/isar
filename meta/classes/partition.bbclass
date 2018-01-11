# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

def load_desc(d):
    import json
    import os

    extractdir = d.getVar('EXTRACTDIR', True)
    layout_file = d.getVar('IMAGE_LAYOUT_FILE', True)
    image_desc_file = os.path.join(extractdir, layout_file)

    with open(image_desc_file) as file:
        dat = file.read()

    return json.loads(dat)



python do_generate_partition_wks() {
    desc = load_desc(d)
    partitions = desc['partitions']

    for partition in partitions:
        bb.note('Generating wks file for %s' % partition)
        part = partitions[partition]

        try:
            dir = part['src-dir']
        except KeyError:
            dir = None

        if part['type'] == 'rootfs':
            if dir:
                directory = '--rootfs-dir=%s' % d.getVar(dir, True)
            else:
                directory = '--rootfs-dir=rootfs'
        else:
            directory = ''

        if part['size'] != -1:
            size = '--fixed-size=%sM' % part['size']
        else:
            size = ''

        src    = '--source %s' % part['type']
        base   = 'part --no-table'
        fstype = '--fstype=%s' % part['filesystem']
        label  = '--label %s' % part['label']

        wks_options = ' '.join([base, src, directory, size, fstype, label])
        extractdir  = d.getVar('EXTRACTDIR', True)
        wks_file = '.'.join([part['label'], part['filesystem'], 'wks'])
        wks_file_loc = os.path.join(extractdir, wks_file)

        f = open(wks_file_loc, 'a')
        f.write(wks_options)
        f.close()
}
addtask do_generate_partition_wks after do_emit_wicvars before do_image
do_generate_partition_wks[stamp-extra-info] = "${MACHINE}"


python do_generate_image_wks() {
    desc = load_desc(d)
    partitions = desc['partitions']

    for image_type in d.getVar('IMAGE_TYPES', True).split():

        extractdir  = d.getVar('EXTRACTDIR', True)
        wks_file = '.'.join([d.getVar('PN', True), image_type, 'wks'])
        wks_file_loc = os.path.join(extractdir, wks_file)

        f = open(wks_file_loc, 'w')

        bootloader = 'bootloader --source bootstream'
        f.write(bootloader)
        f.write('\n')

        for partition in sorted(partitions.items(), key=lambda x: x[1]['num']):
            bb.note('Adding partition %s to wks file for %s' % (partition[0], image_type))
            part = partition[1]

            try:
                dir = part['src-dir']
            except KeyError:
                dir = None

            if part['type'] == 'rootfs':
                if dir:
                    directory = '--rootfs-dir=%s' % d.getVar(dir, True)
                else:
                    directory = '--rootfs-dir=rootfs'
            else:
                directory = ''

            if part['size'] != -1:
                size = '--fixed-size=%sM' % part['size']
            else:
                size = ''

            src   = '--source %s' % part['type']
            base  = 'part %s' % part['mountpoint']
            align = '--align 2048'
            fstype = '--fstype=%s' % part['filesystem']
            label  = '--label %s' % part['label']
            wks_options = ' '.join([base, src, align, directory, size, fstype, label])

            f.write(wks_options)
            f.write('\n')

        f.close()

}
addtask do_generate_image_wks after do_emit_wicvars before do_image
do_generate_image_wks[stamp-extra-info] = "${MACHINE}"
