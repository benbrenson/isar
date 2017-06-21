DESCRIPTION = "Multistrap target filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

inherit debian-image initramfs

IMAGE_NAME = "${PN}-${PV}-${MACHINE}-${DISTRO_ARCH}"

DEV_PACKAGES=" \
              gcc \
              gdb \
              i2c-tools \
              can-utils \
              cmake \
              git \
              build-essential \
              trace-cmd \
              device-tree-compiler \
              python-pip \
              python3-dev \
              python3-pip \
              strace \
             "

ADD_INSTALL = "${@bb.utils.contains('IMAGE_FEATURES', 'develop', ${DEV_PACKAGES}, '', d)}"

IMAGE_PREINSTALL += " \
                    ${ADD_INSTALL} \
                    "

IMAGE_PREINSTALL += "apt \
                     dbus"


ROOTFS_EXTRA="100"
