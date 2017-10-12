DESCRIPTION = "A framework for streaming media."
DESCRIPTION_TOOLS = "Tools making use of the gstreamer library."
LICENSE = "gpl2"

inherit dpkg debianize

DEB_DEPENDS = "libv4l-dev libglib2.0-dev"
DEB_DEPENDS_class-cross = "libv4l-dev-cross libglib2.0-dev-cross"


CONFIGURE = "./configure --prefix=${S}/debian/tmp"
CONFIGURE_class-cross = "./configure --host=${TARGET_PREFIX} --prefix=${PPS}/debian/tmp"

URL = "git://github.com/GStreamer/gstreamer.git"
SRCREV = "e838007d096cefd0f500cde86a4ca550930ca40b"
BRANCH = "master"

SECTION  = "utils"
PRIORITY = "optional"

SRC_DIR="git"
SRC_URI += " \
         ${URL};branch=${BRANCH};protocol=https \
         file://debian \
         "


# Add description for tools binary package
do_generate_debcontrol_append() {
    sed -i -e 's/##DESCRIPTION_TOOLS##/${DESCRIPTION_TOOLS}/g'   ${CONTROL}
}


debianize_build() {
	@echo "Running build target."
	./autogen.sh --noconfigure
	${CONFIGURE}
	make -j${PARALLEL_MAKE}
}


debianize_install() {
	@echo "Running install target."
	dh_testdir
	dh_testroot
	dh_clean  -k
	make install
}

BBCLASSEXTEND = "cross"