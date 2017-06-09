inherit cross-compile

# Build package from sources
do_build() {
    cd ${S}
    dpkg-buildpackage ${DEB_SIGN} -pgpg -sn --host-arch=${DEB_ARCH} -Z${DEB_COMPRESSION}
}
do_build[stamp-extra-info] = "${DISTRO}"



# Install package to dedicated deploy directory
do_install() {
    install -m 755 ${S}/../*.deb ${DEPLOY_DIR_DEB}/
}
do_install[dirs]="${DEPLOY_DIR_DEB}"
do_install[stamp-extra-info] = "${DISTRO}"
