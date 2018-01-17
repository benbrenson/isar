inherit apt-cache


# Setup the apt cache, load snapshot of last build.
do_cache_setup() {
    set -E
    _cleanup() {
        ret=$?
        bbwarn "Error in apt-cache.bblcass: ${BASH_SOURCE[0]}: (Line ${BASH_LINENO[0]}, Func:${FUNCNAME[1]})"
        (exit $ret) || bb_exit_handler
    }
    trap '_cleanup' ERR

    # Very first build of isar. Setting up the cache.
    if [ ! -e "${CFG_FILE}" ]; then
        bbplain "Creating local apt cache for first build."
        sed -e 's|##CACHE_DIR##|${CACHE_DIR}|' \
            ${FILESDIR}/${CACHE_CFG_FILE}.in > ${CFG_FILE} || rm ${CFG_FILE}

        _repo_db_create ${ISAR_REPO_LOCAL} ${ISAR_CACHE_LOCAL_PREFIX}
        _repo_db_publish ${ISAR_REPO_LOCAL} ${ISAR_CACHE_LOCAL_PREFIX}
    fi

    if [ -e "${ISAR_FIRST_BUILD_DONE}" ] && [ "${REPRODUCIBLE_BUILD_ENABLED}" == "1" ]; then
        cache_load_snapshot ${SNAPSHOT_BASENAME}_${MACHINE}
    fi
}
addtask do_cache_setup before do_install
do_cache_setup[dirs] += "${CACHE_CONF_DIR}"
do_cache_setup[lockfiles] = "${DPKG_LOCK}"


# Anchor for supporting proper dependency chain
do_install() {
  :
}
addtask do_install after do_cache_setup
