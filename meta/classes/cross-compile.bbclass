# Class for running builds with cross-compile support.
# Since qemu emulated compilation suffers under bad performance,
# cross compiling can solve this problem, especially in development
# state.
inherit fetch

DEPENDS += "cross-toolchain"
do_build[deptask] = "do_install"

PATH_prepend="${TOOLCHAINDIR}/bin:"

export CROSS_COMPILE="arm-linux-gnueabihf-"
export CCARCH="${TARGET_ARCH}"
export ARCH="${TARGET_ARCH}"

EXTRACTDIR="${WORKDIR}"
S = "${EXTRACTDIR}/${SRC_DIR}"

python () {
    s = d.getVar('S', True).rstrip('/')
    extract_dir = d.getVar('EXTRACTDIR', True).rstrip('/')

    if s == extract_dir:
        bb.fatal('\nS equals EXTRACTDIR. Maybe SRC_DIR variable was not set.')
}

# Build package from sources
do_build() {
    bbwarn "No function provided. Need to overwrite."
}
do_build[stamp-extra-info] = "${DISTRO}"



# Install package to dedicated deploy directory
do_install() {
    bbwarn "No function provided. Need to overwrite."
}
do_install[stamp-extra-info] = "${MACHINE}"
addtask do_install after do_build