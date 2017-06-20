DESCRIPTION = "Multistrap target filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

inherit debian-image initramfs

IMAGE_NAME = "${PN}-${PV}-${MACHINE}-${DISTRO_ARCH}"

IMAGE_PREINSTALL += "apt \
                     dbus"


ROOTFS_EXTRA="100"
