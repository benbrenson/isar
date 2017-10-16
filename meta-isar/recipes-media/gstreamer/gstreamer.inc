SECTION  = "utils"
PRIORITY = "optional"

SRC_DIR="git"
SRC_URI += " \
         ${URL};branch=${BRANCH};protocol=https \
         file://debian \
         "

export PKG_CONFIG_PATH="/usr/lib/pkgconfig"

CONFIGURE = "./configure --prefix=${PPS}/debian/tmp${prefix} ${EXTRA_CONF}"
CONFIGURE_class-cross = "./configure --host=${TARGET_PREFIX} --prefix=${PPS}/debian/tmp${prefix} ${EXTRA_CONF}"

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
	dh_clean -k
	make install
}