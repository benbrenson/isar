# This software is a part of ISAR.
# Copyright (C) 2017 Mixed-Mode GmbH

inherit dpkg-cross

CLASSOVERRIDE = "class-cross"

CROSS_COMPILE="arm-linux-gnueabihf"
TARGET_PREFIX="arm-linux-gnueabihf"
CCARCH="${TARGET_ARCH}"
ARCH="${TARGET_ARCH}"