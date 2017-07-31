# ex:ts=4:sw=4:sts=4:et
# -*- tab-width: 4; c-basic-offset: 4; indent-tabs-mode: nil -*-
#
# Additions implementations for isar buildsysem
#
# Copyright (C) 2017  Mixed Mode GmbH
#
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
# Based on functions from the base bb module, Copyright 2003 Holger Schurig

import sys

class DummyConfigParameters(bb.cookerdata.ConfigParameters):
    """ Class for generating Dummy config parameters. Required for creating valid
        cookerdata.ConfigParameters and setting these within cookerdata.CookerConfiguration
        with cookerdata.CookerConfiguration.setConfigParameters().
    """
    def __init__(self, **options):
        self.initial_options = options
        super(DummyConfigParameters, self).__init__()

    def parseCommandLine(self, argv=sys.argv):
        class DummyOptions:
            def __init__(self, initial_options):
                for key, val in initial_options.items():
                    setattr(self, key, val)

        return DummyOptions(self.initial_options), None