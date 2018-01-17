# This software is a part of ISAR.
# Copyright (C) 2017-2018 Mixed-Mode GmbH
#
# This class implements common functionality for the apt cache.
#
# Todo:
# 1. When a function of this API return an error, bitbake should output the last function produced the error!
#
# 2. Add functionality of creating snapshots of local isar repo.
#
#
CFG_FILE = "${CACHE_CONF_DIR}/${CACHE_CFG_FILE}"
SNAPSHOT_BASENAME="repo-snapshot"
ISAR_REPO_LOCAL = "isar-repo-local"
ISAR_FIRST_BUILD_DONE = "${CACHE_DIR}/${MACHINE}.first_build_done"

# Reproducible build is not default
REPRODUCIBLE_BUILD_ENABLED ?= "1"


# Rename a snapshot
# $1: Old name.
# $2: New name.
_snapshot_rename() {
	aptly -config=${CFG_FILE} snapshot rename $1 $2
}

# Delete a snapshot
# $1: Snapshot name
_snapshot_delete() {
    aptly -config=${CFG_FILE} \
          snapshot drop \
          $1 || bbnote "No snapshot to delete"
}


# Create a snapshot
# $1: Snapshot name.
_snapshot_create() {
    aptly -config=${CFG_FILE} \
          snapshot create \
          $1 from repo \
          ${ISAR_REPO_LOCAL}
}


# Create the actual repository for given snapshot.
# $1: Snapshot name.
_snapshot_publish() {
    aptly -config=${CFG_FILE} \
          publish snapshot $1 \
          ${ISAR_CACHE_LOCAL_PREFIX}
}


# Create a new repository database for Isar generated packages.
# $1: Repository database name
_repo_db_create() {
    aptly -config=${CFG_FILE} \
          repo create \
          -component="main" \
          -distribution="${DISTRO_SUITE}" \
          $1
}

# Create a new repository database for Isar generated packages, but
# use a snapshot as source.
# $1: Repository database name.
# $2: Snapshot name
_repo_db_create_from_snapshot() {
    aptly -config=${CFG_FILE} \
          repo create \
          -component="main" \
          -distribution="${DISTRO_SUITE}" \
          $1 \
          from snapshot \
          $2
}



# Drop a created repository database silenty.
_repo_db_drop() {
    aptly -config=${CFG_FILE} \
          repo drop -force \
          ${ISAR_REPO_LOCAL} || bbnote "No db to drop"

}


# Add packages to the local repository database.
# $1: Repository database name.
# $*: Packages to add.
_repo_db_add_package() {
    repo=$1
    shift
    aptly -config=${CFG_FILE} repo add -force-replace $repo $*
}


# Delete packages from the repository database.
# $1: Repository database name.
# $*: Packages to delete.
_repo_db_delete_package() {
    repo=$1
    shift
    aptly -config=${CFG_FILE} repo remove $repo $*
}


# Publish repository consumed by apt. This function can only be called
# for repositories
# $1: Repository database name
# $2: Path Prefix
_repo_db_publish() {
    aptly -config=${CFG_FILE} \
          publish repo \
          -architectures="${DEB_HOST_ARCH},${DISTRO_ARCH}" \
          $1 \
          $2

}


# Drop an already published repository.
# $1: Path prefix
_repo_db_publish_drop() {
    aptly -config=${CFG_FILE} \
          publish drop \
          ${DISTRO_SUITE} \
          $1 || bbnote "Nothing to publish"
}


# Switch already published repository to new repository. This
# will change the content of the published repository. This function
# can only be called on published repos.
# $1: Prefix.
cache_update_repo() {
    aptly -config=${CFG_FILE} \
          publish update \
          -force-overwrite \
          ${DISTRO_SUITE} $1
}


# Add packages to the isar cache.
# $1: Repository database name.
# $2: Repository prefix
# $*: Packages to add.
cache_add_package() {
    repo=$1
    prefix=$2
    shift 2
    _repo_db_add_package $repo $*
    cache_update_repo $prefix
}


# Delete a package from the apt cache.
# This function is used to be called within do_clean(all) task.
# $1: Repository database name.
# $2: Repository prefix
# $*: Packages to delete.
cache_delete_package() {
    repo=$1
    prefix=$2
    shift 2
    _repo_db_delete_package $repo $*
    cache_update_repo $prefix
}


# Create a snapshot, from current repository state
cache_create_snapshot() {
    _repo_db_publish_drop ${ISAR_CACHE_LOCAL_PREFIX}
    _snapshot_delete ${SNAPSHOT_BASENAME}_${MACHINE}
    _snapshot_create ${SNAPSHOT_BASENAME}_${MACHINE}
    _repo_db_publish ${ISAR_REPO_LOCAL} ${ISAR_CACHE_LOCAL_PREFIX}
}

# Load the last snapshot and publish it
cache_load_snapshot() {
    last_snapshot=$(aptly --config=${CFG_FILE} --raw -sort=time snapshot list | grep "$1" | tail -n 1)

    if [ -z "$last_snapshot" ]; then
        bbfatal "Requesting snapshot which has never been created. Repository may be in a inconsistent state. Totally new and clean build required."
    fi
    bbplain "Loading last snapshot: $last_snapshot"
    _repo_db_publish_drop ${ISAR_CACHE_LOCAL_PREFIX}
    _repo_db_drop
    _repo_db_create_from_snapshot ${ISAR_REPO_LOCAL} ${SNAPSHOT_BASENAME}_${MACHINE}
    _repo_db_publish ${ISAR_REPO_LOCAL} ${ISAR_CACHE_LOCAL_PREFIX}
}

