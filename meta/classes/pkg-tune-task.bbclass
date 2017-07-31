# This software is a part of ISAR.
# Copyright (C) 2017 Mixed Mode GmbH

# This class provides the functionality of adding package customizations for
# debian standard packages.

python do_package_tunes() {
    import bb.cooker
    import bb.add

    # Check if packages in PACKAGE_TUNE contains packages, which
    # where not listed in IMAGE_PREINSTALL or IMAGE_INSTALL.
    # If not so skipp customization for this packages.
    img_preinstall = d.getVar('IMAGE_PREINSTALL', True)
    img_install    = d.getVar('IMAGE_INSTALL', True)
    pkg_tunes      = d.getVar('PACKAGE_TUNES', True)
    tunes_skipp    = []

    if not pkg_tunes:
        return

    for tune in pkg_tunes.split():
        if tune not in img_preinstall and tune not in img_install:
            bb.warn('Skipping package tune for %s since it is not going to be installed. Please add %s to IMAGE_PREINSTALL or IMAGE_INSTALL' % (tune,tune))
            tunes_skipp.append(tune)


    # Now parse files selected with PACKAGE_TUNES and run tasks of each file.
    # We need to go this way in order to run tasks in foreign recipes at a defined point
    # of execution.
    # Otherwise it is only possible to set the tasks (of this recipe) point of execution
    # after the execution point of the foreign recipes task.
    # But in case of PACKAGE_TUNES, these foreign recipes task should be executed after
    # do_post_rootfs() has finished.

    # Get collections
    # A collection object stores information and methods about bbfiles as well as a list
    # of bbfiles.
    bbfile_config_priorities = []
    collection = bb.cooker.CookerCollectFiles(bbfile_config_priorities)
    bbfiles, masked = collection.collect_bbfiles(d, None)

    configparams = bb.add.DummyConfigParameters()

    # Run a parse of configuration data for a recipes' environment
    configuration = bb.cookerdata.CookerConfiguration()
    configuration.setConfigParameters(configparams)

    # Get the databuilder, which is responsible for holding
    # config related information.W
    databuilder = bb.cookerdata.CookerDataBuilder(configuration, False)
    databuilder.parseBaseConfiguration()
    parser = bb.cache.NoCache(databuilder)

    tunes = d.getVar('PACKAGE_TUNES', True) or ""

    for tune in tunes.split():

        if tune in tunes_skipp:
            continue

        for bbfile in bbfiles:
            if '_tune.bb' not in bbfile:
                continue

            appendfiles = collection.get_file_appends(bbfile)

            if tune in bbfile:
                bb.note('Loading data from {}'.format(bbfile))
                data = parser.loadDataFull(bbfile, appendfiles)

                if data.getVar('do_configure_tune', False) != None:
                    bb.build.exec_func('do_configure_tune', data)
                if data.getVar('do_install_tune', True) != None:
                    bb.build.exec_func('do_install_tune', data)


}
addtask do_package_tunes after do_post_rootfs before do_build


