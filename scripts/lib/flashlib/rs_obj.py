#!/usr/bin/env python3
import re

class ResizePartition(object):
    """ Represents a single partition resize definition.
    """
    def __init__(self, size, num, unit):
        self.size = size
        self.num =  num
        self.unit = unit

    def __le__(self, other):
        return self.num < other.num

    def __eq__(self, other):
        return self.num == other.num

    def __gt__(self, other):
        return self.num > other.num

    def __str__(self):
        s = ("ResizePartition instance --\n"
             "partnum: %(num)r, size: %(size)r, unit: %(unit)r \n" %
             {"num" : self.num, "size" : self.size, "unit" : self.unit })

        return s

class ResizePartitions(object):
    """ Represents all partitions which have to be resized.
        All properties have to be present in the rstring parameter.
        @rstring: String containing resize options for partitions.
    """
    def __init__(self, rstring):
        self.partitions = list()
        if len(rstring) != 0:
            for desc in rstring.split(','):
                _partnum  = int(desc.split(':')[0])
                _sizepunit= desc.split(':')[1]
                _size     = int(re.sub('\D', '', _sizepunit))
                _unit     = re.sub('\d', '', _sizepunit)

                _obj = ResizePartition(_size, _partnum, _unit)
                self.partitions.append(_obj)

        self.partitions.sort()

    def getMax(self):
        if not self.isEmpty():
            return max(self.partitions)

    def rmMax(self):
        del self.partitions[-1:]

    def isEmpty(self):
        return len(self.partitions) == 0


    def __str__(self):
        s = ("ResizePartitions instance --\n"
             "partitions: %(part)r \n" %
             {"part" : self.partitions})
        return s

