SECTION  = "utils"
PRIORITY = "optional"

inherit dpkg debianize

DEB_DEPENDS += "autoconf-archive \
		libcmocka0 \
		libcmocka-dev \
		build-essential \
		git \
		pkg-config \
		gcc \
		g++ \
		m4 \
		libtool \
		automake \
		autoconf \
		"

SRC_DIR="git"
SRC_URI += " \
         ${URL};branch=${BRANCH};protocol=https \
         file://debian \
         "

export PKG_CONFIG_PATH="/usr/lib/pkgconfig"

PKG_CONFIG_DIR = "${S}/debian/tmp/usr/lib/pkgconfig/*"

debianize_build() {
	@echo "Running build target."
	./bootstrap
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
