# ex:ts=4:sw=4:sts=4:et
# -*- tab-width: 4; c-basic-offset: 4; indent-tabs-mode: nil -*-
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
# This implements the installation of bootstream onto disk images.
# Mainly this means deploying uboot or barebox bootloaders.
#
# AUTHORS
# Benedikt Nidermayr <Benedikt.Niedermayr@mixed-mode.de>

import logging
import os

from wic import WicError
from wic.pluginbase import SourcePlugin
from wic.utils.misc import exec_cmd, get_bitbake_var
from wic.filemap import sparse_copy

logger = logging.getLogger('wic')

blocksize = '8192'


class BootStreamPlugin(SourcePlugin):
    name = 'bootstream'

    @classmethod
    def do_install_disk(cls, disk, disk_name, creator, workdir, oe_builddir,
                        bootimg_dir, kernel_dir, native_sysroot):
        """
        Called after all partitions have been prepared and assembled into a
        disk image.  This provides a hook to allow finalization of a
        disk image e.g. to write an MBR to it.
        """
        logger.debug("SourcePlugin: do_install_disk: disk: %s", disk_name)
        print('DISK: %s' % disk)
        print('DISKIMAGE: %s' % disk.path)

        if not bootimg_dir:
            bootimg_dir = get_bitbake_var("DEPLOY_DIR_IMAGE")
            if not bootimg_dir:
                raise WicError("Couldn't find DEPLOY_DIR_IMAGE, exiting")

        boot_image = get_bitbake_var('BOOT_IMG')
        if not boot_image:
            raise WicError("Couldn't find BOOT_IMG, exiting")

        boot_image_path =  bootimg_dir + '/' + boot_image

        # TODO: Does bootstream overwrite MBR/GPT or first partition space?

        install_cmd = "dd if=%s of=%s bs=%s seek=%s conv=notrunc" % (boot_image_path, disk.path, blocksize, 1)
        exec_cmd(install_cmd)
