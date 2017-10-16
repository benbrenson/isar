DESCRIPTION = "Bad plugins for gstreamer."
DESCRIPTION_DEV = "Header files of gstreamer bad plugins."
LICENSE = "gpl2"

inherit dpkg debianize pkgconfig
include gstreamer.inc

PROVIDES += "gst-plugins-bad-dev"
PROVIDES_class-cross += "gst-plugins-bad-dev-cross"

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

URL = "git://github.com/GStreamer/gst-plugins-bad.git"
SRCREV = "0355bb7c348fd57930477a03da56a66b42bd0074"
BRANCH = "master"

# Add description for tools binary package
do_generate_debcontrol_append() {
    sed -i -e 's/##DESCRIPTION_DEV##/${DESCRIPTION_DEV}/g' ${CONTROL}
}

EXTRA_CONF ?= ""

BBCLASSEXTEND = "cross"