import os
import os.path
import sys
import parted
import re
import time

from flashlib import rs_obj
from flashlib import utils
from flashlib.command import Command as Cmd


class Disk(parted.Disk):
    """ Disk()
        Represents a higher level piece of a block device, extending the Disk class from parted module
        with usefull filesystem operations, e.g. creating filesystems.
    """
    def __init__(self, *methodName, **kwargs):
        super(Disk, self).__init__(*methodName, **kwargs)

    def getLastPartition(self):
        return self.partitions[-1]



class BlockDevHandler():
    """
    BlockDevHandler methods:
    umount: Umount all partitions of device if mounted
    clear: Clear the complete @device
    flash: Write the image file to device (This means the complete device containing all partitions will be written)


    BlockDevHandler attributes:
    blkdev: High Level block device.
    disk: Block device containing partitions.
    rsz_objs: Resize objects.

    """

    # TODO: use disk.setPartitionGeometry() instead of removing and adding again?
    #       Does this satisfy the constrains?



    def __init__(self, file, device, size_desc=''):
        """ Get device and initialize class """

        self._loadDisk(device)
        self.device_file = device
        self.imgfile = file
        self.rsz_objs = rs_obj.ResizePartitions(size_desc)


    def _deviceIsPartition(self, device):
        """ Check if specified devicefile is a complete device or
            only a partition.
        """
        mmcdev_part  = re.compile('mmcblk[0-9]p[0-9]')
        scsidev_part = re.compile('sd[a-z][0-9]')

        if mmcdev_part.search(device) != None:
            return True
        if scsidev_part.search(device) != None:
            return True

        return False


    def _loadDisk(self, device):
        """ Load the partitioned device and underlying disk. """
        self.blkdev = parted.getDevice(device)

        # Check if disk has partitions
        try:
            self.disk = Disk(self.blkdev)
        except:
            self._isEmpty = True

        self._isEmpty = False


    def _copyPartition(self, part_old, part_new):
        """ Copy a partition to another region.

            @part_old: Partition object from old region(must contain a valid Geometry object).
            @part_new: Partition object from new region(must contain a valid Geometry object).
        """

        if part_new.getLength() < part_old.getLength():
            raise Exception('New partition must have at least same length as long partition.')

        towrite_sec = part_old.getLength()
        _offset_sec = 0
        print('Starting deep copy (%s sectors) at %s' % (towrite_sec, part_new.geometry.start))

        with open(self.blkdev.path, 'rb+') as w:
            while towrite_sec > 0:
                # Old partition pos
                w.seek((part_old.geometry.start + _offset_sec) * self.blkdev.sectorSize, 0)

                # Minimize seeks
                if towrite_sec > self.blkdev.sectorSize*1024*2:
                    _next = self.blkdev.sectorSize*1024*2
                else:
                    _next = self.blkdev.sectorSize

                _buf = w.read(_next)

                if len(_buf) < self.blkdev.sectorSize:
                    raise Exception('Read returns less bytes than sector size!')

                # New partition pos
                w.seek((part_new.geometry.start + _offset_sec) * self.blkdev.sectorSize, 0)
                w.write(_buf)

                towrite_sec -= int(len(_buf)/self.blkdev.sectorSize)
                _offset_sec += int(len(_buf)/self.blkdev.sectorSize)


        print('Written %s sectors' % _offset_sec)


    def _movePartition(self, partition, start, end):
        """ Move any partition object on disk and resize it if needed.
            @partition: Partition object to be moved.
            @start: New start position of partition object(maybe recalculated).
            @end: New end position of partition object(maybe recalculated).

            Note: The selected start and end parameters maybe recalculated after creating the
                  the partition, in order to fit best alignment for the block device.
                  This method returns the new partition object, with exact start and end values.
        """

        # Remove old partition
        self.disk.removePartition(partition)

        # print('New location(calculated):')
        # print('First sector %s' % _start)
        # print('Last sector %s' % _end)
        # print('Size: %s (%s)' % (_len, _end -_start))

        _geometry = parted.Geometry(device=self.blkdev,
                                    start=start,
                                    end=end)

        _filesystem = parted.FileSystem(type=partition.fileSystem.type,
                                        geometry=_geometry)

        _partition = parted.Partition(disk=self.disk,
                                      type=parted.PARTITION_NORMAL,
                                      fs=_filesystem,
                                      geometry=_geometry)

        self.disk.addPartition(partition=_partition,
                                   constraint=self.blkdev.optimalAlignedConstraint)

        # get the new partition after adding it (position is now optimized)
        _new = self.disk.getPartitionByPath(partition.path)

        # print('New location(corrected):')
        # print('First sector %s' % _part_new.geometry.start)
        # print('Last sector %s' % _part_new.geometry.end)
        # print('Size: %s (%s)' % (_part_new.getLength(), _part_new.geometry.end - _part_new.geometry.start))

        return _new


    def _resizePartition(self, partition):
        """ Resize partition with the underlying resize2fs command. """
        cmd = Cmd('e2fsck -yf {0}'.format(partition.path))
        cmd.run(debug=True,check=True)

        cmd = Cmd('resize2fs -p {0}'.format(partition.path))
        cmd.run(debug=True,check=True)


    def _resizeDevicePartitions(self):
        """ Resize the rootfs partitions of the device. """
        print('Resizing partitions...')

        if self.isEmpty():
           print('Warning: Nothing to resize. Device is empty.')
           return

        _end = self.blkdev.getLength() - 1

        for part in self.disk.partitions[::-1]:

            if self.rsz_objs.isEmpty():
                return

            _rsz_obj = self.rsz_objs.getMax()
            _num  = _rsz_obj.num

            if part.number == _num:
                _size = parted.sizeToSectors(_rsz_obj.size, _rsz_obj.unit, self.blkdev.sectorSize)
                _skipp_resize = False
            elif part.number > _num:
                _size = part.getLength()
                _skipp_resize = True
            else:
                print('Resize/move done.')
                return

            # Move partition
            _len = _size
            _start = _end - _len
            _part_new = self._movePartition(part, _start, _end)
            _end = _start


            # Deep copy to new region
            self._copyPartition(part, _part_new)
            os.sync()
            self.disk.commit()
            cmd = Cmd('partprobe')
            cmd.run(debug=True)
            time.sleep(10)

            # Resize partition
            if not _skipp_resize:
                self._resizePartition(part)
                self.rsz_objs.rmMax()


    def isEmpty(self):
        """ Check if device is empty. """
        return self._isEmpty


    def clearDevice(self):
        """ Nothing to be done for MMCs, only in save mode. """
        pass


    def umount(self):
        """ Umount all filesystems for given device. """
        if self.isEmpty():
            print('Nothing to umount, since device is empty.')
            return

        for part in self.disk.partitions:
            _cmd = Cmd('umount %s' % part.path)
            print(_cmd.orig_cmd)
            _cmd.run(check=False)


    def flashDevice(self, check=True):
        """ Write specified file to block device.
            If the destination device is a single partition (e.g. mmcblk0p1) then
            the device file is simply written to the partition.
            If the destination device is the complete device (e.g. mmcblk0) then
            the image file is getting written to the device and all partition where
            resized, when specified.

            @check: Disable hash integrity check (default=True).
        """
        print('Flashing device...')

        inhash = utils.getHasher()

        written  = 0

        with open(self.blkdev.path, 'wb') as w:
            while True:
                buf = self.imgfile.read(self.blkdev.sectorSize)
                inhash.update(buf)

                if len(buf) == 0:
                    break

                w.write(buf)
                written += len(buf)

        if check == True:
            devfile_hash = utils.calcHash(self.blkdev.path, self.blkdev.sectorSize, written)
            if devfile_hash != inhash.hexdigest():
                raise Exception('Integrity check failed!')

        os.sync()
        self._loadDisk(self.blkdev.path)

        if self._deviceIsPartition(self.blkdev.path):
            self._resizePartition(self.blkdev)
        else:
            self._resizeDevicePartitions()