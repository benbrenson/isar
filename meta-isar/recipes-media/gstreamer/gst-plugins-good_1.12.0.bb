DESCRIPTION = "Good plugins for gstreamer."
LICENSE = "gpl2"

inherit dpkg debianize pkgconfig
include gstreamer.inc

DEPENDS = "gstreamer \
           gstreamer-dev \
           gst-plugins-base \
           gst-plugins-base-dev \
          "
DEPENDS_class-cross = "gstreamer-cross \
                       gstreamer-dev-cross \
                       gst-plugins-base-cross \
                       gst-plugins-base-dev-cross \
                      "

DEB_DEPENDS = "libv4l-dev"
DEB_DEPENDS_class-cross = "libv4l-dev-cross"

URL = "git://github.com/GStreamer/gst-plugins-good.git"
SRCREV = "09af01a08852265c76bd1b0b9d8fe42ed2a1c919"
BRANCH = "master"

SRC_URI += "file://0001-gstv4l2videoenc-Fixed-EBUSY-when-setting-format.patch"

EXTRA_CONF ?= "--with-libv4l2 --enable-v4l2-probe"

BBCLASSEXTEND = "cross"