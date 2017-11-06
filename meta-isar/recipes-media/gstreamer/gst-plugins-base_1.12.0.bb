DESCRIPTION = "Base plugins for gstreamer."
DESCRIPTION_DEV = "Header files of gstreamer base plugins."
LICENSE = "gpl2"

inherit dpkg debianize pkgconfig
include gstreamer.inc

PROVIDES += "gst-plugins-base-dev"
PROVIDES_class-cross += "gst-plugins-base-dev-cross"

DEPENDS = "gstreamer gstreamer-dev"
DEPENDS_class-cross = "gstreamer-cross gstreamer-dev-cross"

URL = "git://github.com/GStreamer/gst-plugins-base.git"
SRCREV = "d4db88772bba139508638354550b87a42f047254"
BRANCH = "master"

# Add description for tools binary package
do_generate_debcontrol_append() {
    sed -i -e 's/##DESCRIPTION_DEV##/${DESCRIPTION_DEV}/g' ${CONTROL}
}

EXTRA_CONF ?= ""

BBCLASSEXTEND = "cross"