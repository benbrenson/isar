DESCRIPTION="Device tree compiler, which is capable of compiling \
device tree overlays. Therefore the '-@' option has to be supported."

include dtc.inc
inherit dpkg debianize

SRCREV="36f511fb1113a8a70defb21b7036882f122aa844"
BRANCH="master"

SRC_DIR="git"
SRC_URI +=" \
         ${URL};protocol=https;branch=${BRANCH} \
         file://debian \
        "
SECTION = "devel"
PRIORITY = "optional"
LICENSE  = "gpl"


###                              ###
### debianize makefile functions ###
###                              ###

debianize_build[target] = "build"
debianize_build() {
	@echo "Running build target."
	rm -rf .git
	make -j${PARALLEL_MAKE}
}


debianize_clean[target] = "clean"
debianize_clean() {
	@echo "Running clean target."
	make clean
}

debianize_install[target] = "install"
debianize_install[tdeps] = "build"
debianize_install() {
	@echo "Running install target."
	dh_testdir
	dh_testroot

	mkdir -p debian/${BPN}
	mkdir -p debian/${BPN}/opt/bin


	install -m 0755 dtc      debian/${BPN}/opt/bin/overlay-dtc
}


BBCLASSEXTEND = "native"