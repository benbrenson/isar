DESCRIPTION = "Ugly plugins for gstreamer."
DESCRIPTION_DEV = "Header files of gstreamer ugly plugins."
LICENSE = "gpl2"

inherit dpkg debianize pkgconfig
include gstreamer.inc

PROVIDES += "gst-plugins-ugly-dev"
PROVIDES_class-cross += "gst-plugins-ugly-dev-cross"

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

URL = "git://github.com/GStreamer/gst-plugins-ugly.git"
SRCREV = "83d7d2f67a81ad0d99aaf616248a6aa57a1e6f01"
BRANCH = "master"

# Add description for tools binary package
do_generate_debcontrol_append() {
    sed -i -e 's/##DESCRIPTION_DEV##/${DESCRIPTION_DEV}/g' ${CONTROL}
}

EXTRA_CONF ?= ""

BBCLASSEXTEND = "cross"