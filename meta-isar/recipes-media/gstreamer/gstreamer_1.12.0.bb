DESCRIPTION = "A framework for streaming media."
DESCRIPTION_TOOLS = "Tools making use of the gstreamer library."
DESCRIPTION_DEV = "Header files of the gstreamer framework"
LICENSE = "gpl2"

inherit dpkg debianize pkgconfig
include gstreamer.inc

PROVIDES += "gstreamer-tools gstreamer-dev"
PROVIDES_class-cross += "gstreamer-tools-cross gstreamer-dev-cross"

DEB_DEPENDS = "libglib2.0-dev"
DEB_DEPENDS_class-cross = "libglib2.0-dev-cross"

URL = "git://github.com/GStreamer/gstreamer.git"
SRCREV = "e838007d096cefd0f500cde86a4ca550930ca40b"
BRANCH = "master"

# Add description for tools binary package
do_generate_debcontrol_append() {
    sed -i -e 's/##DESCRIPTION_TOOLS##/${DESCRIPTION_TOOLS}/g' ${CONTROL}
    sed -i -e 's/##DESCRIPTION_DEV##/${DESCRIPTION_DEV}/g'     ${CONTROL}
}

EXTRA_CONF ?= ""

BBCLASSEXTEND = "cross"