# ex:ts=4:sw=4:sts=4:et
# -*- tab-width: 4; c-basic-offset: 4; indent-tabs-mode: nil -*-
#
# Copyright (c) 2013-2016 Intel Corporation.
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# DESCRIPTION
# This module provides the OpenEmbedded partition object definitions.
#
# AUTHORS
# Tom Zanussi <tom.zanussi (at] linux.intel.com>
# Ed Bartosh <ed.bartosh> (at] linux.intel.com>
# Benedikt Niedermayr <Benedikt.Niedermayr> (at] mixed-mode.de>

import logging
import os
import tempfile
import time

from wic import WicError
from wic.utils.misc import exec_cmd, exec_native_cmd, get_bitbake_var
from wic.pluginbase import PluginMgr

logger = logging.getLogger('wic')

class Partition():

    def __init__(self, args, lineno):
        self.args = args
        self.active = args.active
        self.align = args.align
        self.disk = args.disk
        self.device = None
        self.extra_space = args.extra_space
        self.exclude_path = args.exclude_path
        self.fsopts = args.fsopts
        self.fstype = args.fstype
        self.label = args.label
        self.mountpoint = args.mountpoint
        self.no_table = args.no_table
        self.num = None
        self.overhead_factor = args.overhead_factor
        self.part_type = args.part_type
        self.rootfs_dir = args.rootfs_dir
        self.size = args.size
        self.fixed_size = args.fixed_size
        self.source = args.source
        self.sourceparams = args.sourceparams
        self.system_id = args.system_id
        self.use_uuid = args.use_uuid
        self.uuid = args.uuid

        self.lineno = lineno
        self.source_file = ""
        self.sourceparams_dict = {}

    def get_extra_block_count(self, current_blocks):
        """
        The --size param is reflected in self.size (in kB), and we already
        have current_blocks (1k) blocks, calculate and return the
        number of (1k) blocks we need to add to get to --size, 0 if
        we're already there or beyond.
        """
        logger.debug("Requested partition size for %s: %d",
                     self.mountpoint, self.size)

        if not self.size:
            return 0

        requested_blocks = self.size

        logger.debug("Requested blocks %d, current_blocks %d",
                     requested_blocks, current_blocks)

        if requested_blocks > current_blocks:
            return requested_blocks - current_blocks
        else:
            return 0

    def get_rootfs_size(self, actual_rootfs_size=0):
        """
        Calculate the required size of rootfs taking into consideration
        --size/--fixed-size flags as well as overhead and extra space, as
        specified in kickstart file. Raises an error if the
        `actual_rootfs_size` is larger than fixed-size rootfs.

        """
        if self.fixed_size:
            rootfs_size = self.fixed_size
            if actual_rootfs_size > rootfs_size:
                raise WicError("Actual rootfs size (%d kB) is larger than "
                               "allowed size %d kB" %
                               (actual_rootfs_size, rootfs_size))
        else:
            extra_blocks = self.get_extra_block_count(actual_rootfs_size)
            if extra_blocks < self.extra_space:
                extra_blocks = self.extra_space

            rootfs_size = actual_rootfs_size + extra_blocks
            rootfs_size *= self.overhead_factor

            logger.debug("Added %d extra blocks to %s to get to %d total blocks",
                         extra_blocks, self.mountpoint, rootfs_size)

        return rootfs_size

    @property
    def disk_size(self):
        """
        Obtain on-disk size of partition taking into consideration
        --size/--fixed-size options.

        """
        return self.fixed_size if self.fixed_size else self.size

    def prepare(self, creator, cr_workdir, oe_builddir, rootfs_dir,
                bootimg_dir, kernel_dir, native_sysroot):
        """
        Prepare content for individual partitions, depending on
        partition command parameters.
        """
        if not self.source:
            if not self.size and not self.fixed_size:
                raise WicError("The %s partition has a size of zero. Please "
                               "specify a non-zero --size/--fixed-size for that "
                               "partition." % self.mountpoint)

            if self.fstype == "swap":
                self.prepare_swap_partition(cr_workdir, oe_builddir,
                                            native_sysroot)
                self.source_file = "%s/fs.%s" % (cr_workdir, self.fstype)
            else:
                if self.fstype == 'squashfs':
                    raise WicError("It's not possible to create empty squashfs "
                                   "partition '%s'" % (self.mountpoint))

                rootfs = "%s/fs_%s.%s.%s" % (cr_workdir, self.label,
                                             self.lineno, self.fstype)
                if os.path.isfile(rootfs):
                    os.remove(rootfs)

                prefix = "ext" if self.fstype.startswith("ext") else self.fstype
                method = getattr(self, "prepare_empty_partition_" + prefix)
                method(rootfs, oe_builddir, native_sysroot)
                self.source_file = rootfs
            return

        plugins = PluginMgr.get_plugins('source')

        if self.source not in plugins:
            raise WicError("The '%s' --source specified for %s doesn't exist.\n\t"
                           "See 'wic list source-plugins' for a list of available"
                           " --sources.\n\tSee 'wic help source-plugins' for "
                           "details on adding a new source plugin." %
                           (self.source, self.mountpoint))

        srcparams_dict = {}
        if self.sourceparams:
            # Split sourceparams string of the form key1=val1[,key2=val2,...]
            # into a dict.  Also accepts valueless keys i.e. without =
            splitted = self.sourceparams.split(',')
            srcparams_dict = dict(par.split('=') for par in splitted if par)

        plugin = PluginMgr.get_plugins('source')[self.source]
        plugin.do_configure_partition(self, srcparams_dict, creator,
                                      cr_workdir, oe_builddir, bootimg_dir,
                                      kernel_dir, native_sysroot)
        plugin.do_stage_partition(self, srcparams_dict, creator,
                                  cr_workdir, oe_builddir, bootimg_dir,
                                  kernel_dir, native_sysroot)
        plugin.do_prepare_partition(self, srcparams_dict, creator,
                                    cr_workdir, oe_builddir, bootimg_dir,
                                    kernel_dir, rootfs_dir, native_sysroot)

        # further processing required Partition.size to be an integer, make
        # sure that it is one
        if not isinstance(self.size, int):
            raise WicError("Partition %s internal size is not an integer. "
                           "This a bug in source plugin %s and needs to be fixed." %
                           (self.mountpoint, self.source))

        if self.fixed_size and self.size > self.fixed_size:
            raise WicError("File system image of partition %s is "
                           "larger (%d kB) than its allowed size %d kB" %
                           (self.mountpoint, self.size, self.fixed_size))

    def prepare_rootfs(self, cr_workdir, oe_builddir, rootfs_dir,
                       native_sysroot):
        """
        Prepare content for a rootfs partition i.e. create a partition
        and fill it from a /rootfs dir.

        Currently handles ext2/3/4, btrfs and vfat.
        """
        pseudo=""
        rootfs = "%s/rootfs_%s.%s.%s" % (cr_workdir, self.label,
                                         self.lineno, self.fstype)
        if os.path.isfile(rootfs):
            os.remove(rootfs)

        # Get rootfs size from bitbake variable if it's not set in .ks file
        if not self.size:
            # Bitbake variable ROOTFS_SIZE is calculated in
            # Image._get_rootfs_size method from meta/lib/oe/image.py
            # using IMAGE_ROOTFS_SIZE, IMAGE_ROOTFS_ALIGNMENT,
            # IMAGE_OVERHEAD_FACTOR and IMAGE_ROOTFS_EXTRA_SPACE
            rsize_bb = get_bitbake_var('ROOTFS_SIZE')
            if rsize_bb:
                logger.warning('overhead-factor was specified, but size was not,'
                               ' so bitbake variables will be used for the size.'
                               ' In this case both IMAGE_OVERHEAD_FACTOR and '
                               '--overhead-factor will be applied')
                self.size = int(round(float(rsize_bb)))

        prefix = "ext" if self.fstype.startswith("ext") else self.fstype
        method = getattr(self, "prepare_rootfs_" + prefix)
        method(rootfs, oe_builddir, rootfs_dir, native_sysroot, pseudo)
        self.source_file = rootfs

        # get the rootfs size in the right units for kickstart (kB)
        du_cmd = "du -Lbks %s" % rootfs
        out = exec_cmd(du_cmd)
        self.size = int(out.split()[0])

    def prepare_rootfs_ext(self, rootfs, oe_builddir, rootfs_dir,
                           native_sysroot, pseudo):
        """
        Prepare content for an ext2/3/4 rootfs partition.
        """
        du_cmd = "du -ks %s" % rootfs_dir
        out = exec_cmd(du_cmd)
        actual_rootfs_size = int(out.split()[0])

        rootfs_size = self.get_rootfs_size(actual_rootfs_size)

        with open(rootfs, 'w') as sparse:
            os.ftruncate(sparse.fileno(), rootfs_size * 1024)

        extra_imagecmd = "-i 8192"

        label_str = ""
        if self.label:
            label_str = "-L %s" % self.label

        mkfs_cmd = "mkfs.%s -F %s %s %s" % \
            (self.fstype, extra_imagecmd, rootfs, label_str)
        exec_cmd(mkfs_cmd)

        rootfs_mnt = rootfs + '.mnt'
        os.makedirs(rootfs_mnt)

        mnt_cmd = 'mount -o loop %s %s' % (rootfs, rootfs_mnt)
        exec_cmd(mnt_cmd)

        if os.listdir(rootfs_dir) != []:
            cpy_cmd = 'cp -aR %s/* %s' % (rootfs_dir, rootfs_mnt)
            exec_cmd(cpy_cmd, as_shell=True)

        os.sync()

        try_cnt = 3
        umnt_cmd = 'umount %s' % rootfs_mnt
        while try_cnt:
            try:
                exec_cmd(umnt_cmd)
                break
            except:
                try_cnt -= 1
                time.sleep(10)

        mkfs_cmd = "fsck.%s -pvf %s" % (self.fstype, rootfs)
        exec_cmd(mkfs_cmd)

    def prepare_rootfs_btrfs(self, rootfs, oe_builddir, rootfs_dir,
                             native_sysroot, pseudo):
        """
        Prepare content for a btrfs rootfs partition.

        Currently handles ext2/3/4 and btrfs.
        """
        du_cmd = "du -ks %s" % rootfs_dir
        out = exec_cmd(du_cmd)
        actual_rootfs_size = int(out.split()[0])

        rootfs_size = self.get_rootfs_size(actual_rootfs_size)

        with open(rootfs, 'w') as sparse:
            os.ftruncate(sparse.fileno(), rootfs_size * 1024)

        label_str = ""
        if self.label:
            label_str = "-L %s" % self.label

        mkfs_cmd = "mkfs.%s -b %d -r %s %s %s" % \
            (self.fstype, rootfs_size * 1024, rootfs_dir, label_str, rootfs)
        exec_cmd(mkfs_cmd)

    def prepare_rootfs_msdos(self, rootfs, oe_builddir, rootfs_dir,
                             native_sysroot, pseudo):
        """
        Prepare content for a msdos/vfat rootfs partition.
        """
        du_cmd = "du -bks %s" % rootfs_dir
        out = exec_cmd(du_cmd)
        blocks = int(out.split()[0])

        rootfs_size = self.get_rootfs_size(blocks)

        label_str = "-n boot"
        if self.label:
            label_str = "-n %s" % self.label

        size_str = ""
        if self.fstype == 'msdos':
            size_str = "-F 16" # FAT 16

        dosfs_cmd = "mkdosfs %s -S 512 %s -C %s %d" % (label_str, size_str,
                                                       rootfs, rootfs_size)
        exec_cmd(dosfs_cmd)

        mcopy_cmd = "export MTOOLS_SKIP_CHECK=1 ; mcopy -i %s -s %s/* ::/" % (rootfs, rootfs_dir)
        exec_cmd(mcopy_cmd, as_shell=True)

        chmod_cmd = "chmod 644 %s" % rootfs
        exec_cmd(chmod_cmd)

    prepare_rootfs_vfat = prepare_rootfs_msdos

    def prepare_rootfs_squashfs(self, rootfs, oe_builddir, rootfs_dir,
                                native_sysroot, pseudo):
        """
        Prepare content for a squashfs rootfs partition.
        """
        squashfs_cmd = "mksquashfs %s %s -noappend" % \
                       (rootfs_dir, rootfs)
        exec_cmd(squashfs_cmd)

    def prepare_empty_partition_ext(self, rootfs, oe_builddir,
                                    native_sysroot):
        """
        Prepare an empty ext2/3/4 partition.
        """
        size = self.disk_size
        with open(rootfs, 'w') as sparse:
            os.ftruncate(sparse.fileno(), size * 1024)

        extra_imagecmd = "-i 8192"

        label_str = ""
        if self.label:
            label_str = "-L %s" % self.label

        mkfs_cmd = "mkfs.%s -F %s %s %s" % \
            (self.fstype, extra_imagecmd, label_str, rootfs)
        exec_cmd(mkfs_cmd)

    def prepare_empty_partition_btrfs(self, rootfs, oe_builddir,
                                      native_sysroot):
        """
        Prepare an empty btrfs partition.
        """
        size = self.disk_size
        with open(rootfs, 'w') as sparse:
            os.ftruncate(sparse.fileno(), size * 1024)

        label_str = ""
        if self.label:
            label_str = "-L %s" % self.label

        mkfs_cmd = "mkfs.%s -b %d %s %s" % \
            (self.fstype, self.size * 1024, label_str, rootfs)
        exec_cmd(mkfs_cmd)

    def prepare_empty_partition_msdos(self, rootfs, oe_builddir,
                                      native_sysroot):
        """
        Prepare an empty vfat partition.
        """
        blocks = self.disk_size

        label_str = "-n boot"
        if self.label:
            label_str = "-n %s" % self.label

        size_str = ""
        if self.fstype == 'msdos':
            size_str = "-F 16" # FAT 16

        dosfs_cmd = "mkdosfs %s -S 512 %s -C %s %d" % (label_str, size_str,
                                                       rootfs, blocks)
        exec_cmd(dosfs_cmd)

        chmod_cmd = "chmod 644 %s" % rootfs
        exec_cmd(chmod_cmd)

    prepare_empty_partition_vfat = prepare_empty_partition_msdos

    def prepare_swap_partition(self, cr_workdir, oe_builddir, native_sysroot):
        """
        Prepare a swap partition.
        """
        path = "%s/fs.%s" % (cr_workdir, self.fstype)

        with open(path, 'w') as sparse:
            os.ftruncate(sparse.fileno(), self.size * 1024)

        import uuid
        label_str = ""
        if self.label:
            label_str = "-L %s" % self.label
        mkswap_cmd = "mkswap %s -U %s %s" % (label_str, str(uuid.uuid1()), path)
        exec_cmd(mkswap_cmd)
