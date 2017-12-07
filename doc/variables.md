# Isar variables
`WORK IN PROGRESS`


 - `DESCRIPTION` - Textual description of a recipes package.
 - `LICENSE` - Application license file.
 - `LIC_FILES_CHKSUM` - Reference to the license file with its checksum. Isar recommends to store license files for your applications into your layer folder `meta-user/licenses/`. Then you may reference it in recipe using the following path:

    ```
    LIC_FILES_CHKSUM = file://${LAYERDIR_isar}/licenses/...
    ```
This approach prevents duplication of the license files in different packages.

 - `SRC_URI` - The link where to fetch application source. Please check the BitBake user manual for supported download formats.
 - `SRC_DIR` - The directory name where application sources will be unpacked. For `git` repositories, it should be set to `git`. Please check the BitBake user manual for supported download formats.
 - `SRC_REV` - Source code revision to fetch. Please check the BitBake user manual for supported download formats.

 - `MACHINE` - Machine type of the selected hardware. MACHINE will configure machine specific information by including the file at `conf/machine/${MACHINE}.conf`.
 - `DISTRO` - Selection of the distribution. DISTRO will configure all distribution specific settings by including the file at `conf/distro/${DISTRO}.conf`. The
 following naming scheme must be used:

    ```
    DISTRO = "<distro>-<distro_suite>"
    ```
Where distro may be "debian" and distro_suite may be "jessie".

 - `SECTION` - Required when debianizing a package. This will set the related `Section` entry in the debian control file.
 - `PRIORITY` - Required when debianizing a package. This will set the related `Priority` entry in the debian control file.
 - `URL` - Required when debianizing a package. This will set the `Homepage` entry in the debian control file.


 - `BBMULTICONFIG` - The list of the machines to include the respective configuration files. This option must contain all potential multiconfigs, otherwise bitbake will raise an KeyError. If this option is omitted, user has to manually define the pair `MACHINE`/`DISTRO` for specific target.
 - `IMAGE_INSTALL` - The list of custom packages to build and install to target image, please refer to relative chapter for more information.
 - `BB_NUMBER_THREADS` - The number of `bitbake` jobs that can be run in parallel. Please set this option according your host CPU cores number.
 - `PARALLEL_MAKE` - Number of parallel makefile instances. Make should be called with -j${PARALLEL_MAKE}
 - `DEB_EMAIL` - The eMail address used by dpkg-buildpackage for setting the `Maintainer` entry in the debian control file.
 - `DEB_FULLNAME` - The name used by dpkg-buildpackage for setting the `Maintainer` entry in the debian control file.
 - `DEB_HOST_ARCH` - The build host architecture (later this should be autodetected).
 - `IMAGE_REVISION` - Only required when swupdate is also integrated as linux update mechanism. This variable is needed by swupdate for detecting the board it will run on.
 - `BROKER_IP` - Only required when running swupdate with the python update service, which in turn is required to receive MQTT messages from a update server/broker.
 - `BROKER_PORT` - See `BROKER_IP`.
 - `UPDATE_TOPIC` - The topic on which the update service will subscribe to, in order to receive update messages from the update server/broker.
 - `IMAGE_FEATURES`- Additional image features (e.g. systemd support or installing a lot of debugging tools on the target).


 - `DISTRO_SUITE` - Repository suite like stable, jessie, wheezy etc.
 - `DISTRO_ARCH` - Machine CPU architecture (e.g. armel, armhf).
 - `DISTRO_COMPONENTS` - Repository components like main, contrib, non-free etc.
 - `DISTRO_APT_SOURCE` - Repository URL.
 - `DISTRO_KEYRINGS` - Keyring packages needed by multistrap to achieve secure repository authentication.

 - `PREFERRED_PROVIDER_virtual/kernel` - Set the kernel recipe name which will be used for the current machine.
 - `PREFERRED_VERSION_virtual/kernel` - Set the kernel recipe version.
 - `PREFERRED_PROVIDER_virtual/bootloader` - Set the bootloader recipe name which will be used for the current machine.
 - `PREFERRED_VERSION_virtual/bootloader` - Set the bootloader recipe version.
 - `FIX_KVERSION` - Complete kernel version. This can be extracted from the kernel makefile. Required for running **depmod** within the rootfs, since kernel recipe doesn't contain complete version (-rc5 is missing).
 - `KERNEL_CMDLINE` - Kernel commandline substituted within uboots bootscript.
 - `TARGET_ARCH` - Some buildsystems (e.g. Kconfig) need architecture specific settings for this type of machine.
 - `TARGET_PREFIX` - Sets the cross compiler prefix for this machine.
 - `KIMAGE_TYPE` - The name of kernel binary that it installed to `/boot` folder in target filesystem. This variable is used by isar for determing which
 image type has to be compiled by the kernel.
 - `MACHINE_SERIAL` - The name of serial device that will be used for console output.
 - `IMAGE_FSTYPES` - The type of images to be generated for this machine (e.g. sdcard).
 - `DTBS` - The primary device tree file. Isar will install this device tree to the location specified with ${DTB_INSTALL_DIR}.
 - `DTBOS` - Device tree overlay files. The kernel has to be capable of compiling device tree overlays.
 - `BOOT_IMG` - The name of the uboot image. Isar will also build a complete debian package for uboot.
 - `UIMAGE_LOADADDR` - The uImage loadaddress. Only required if ${KIMAGE_TYPE} is uImage.
 - `TARGET_ARCH` - The target architecture required by different buildsystems (e.g. Kconfig). Please do not set a debian specific architecture type here.
 - `BOOT_DEVICE_NAME` - Name of the boot device, interpreted by uboot commands.
 - `BOOT_DEVICE_NUM` - Number or interface identifier, interpreted by uboot commands.
 - `BOOTP_PRIM_NUM` - Number of the primary boot partition. This will set the primary boot partition on the first boot by uboot.
 - `BOOTP_SEC_NUM` - Number of the secondary boot partition. This will set the secondary boot partition on the first boot by uboot.
 - `ROOTDEV_PRIM` - Interface for the primary rootfs partition, interpreted by the linux kernel on the kernel cmdline. This variable is also used to detect the partition which should be updated.
 - `ROOTDEV_SEC` - Interface for the secondary rootfs partition, interpreted by the linux kernel on the kernel cmdline. This variable is also used to detect the partition which should be updated.


 - `DEPLOY_DIR` - Base for deploy directories pointing to `${TMPDIR}/deploy`.
 - `DEPLOY_DIR_DEB` - Directory containing all installed deb packages, pointing to `${DEPLOY_DIR}/deb/${MACHINE}`.
 - `DEPLOY_DIR_IMAGE` - Location where build fragments (rootfs images, kernel, bootloader etc.), pointing to `${DEPLOY_DIR}/images/${MACHINE}`.
 - `DEPLOY_DIR_BIN` - Location where global binaries can be installed, pointing to `${DEPLOY_DIR}/bin`.
 - `CHROOT_DEPLOY_DIR_DEB` - Directory where `DEPLOY_DIR_DEB` is mounted and accessible within chroot environments.
 - `BUILDCHROOT_DIR` - Directory where the target architecture rootfs is installed. This rootfs is needed for compiling all target specific software packages where build with qemu support. Pointing to `${TMPDIR}/work/buildchroot/${DISTRO}`.
 - `CROSS_BUILDCHROOT_DIR` - Directory where the cross build rootfs is installed. This rootfs is needed for cross and also native host architecture compilation of software packages.
 - `PN` - Package name, also containing package suffixes.
 - `PV` - Package version.
 - `PR` - Package revision. This can be handled like an extended package version.
 - `ROOTFS_DIR` - Directory where the final rootfs for the target is installed.
 - `P` - Addition of package name and package version (`${PN}-${PV}`).
 - `PF` - Full package identifier (`${PN}-${PV}-${PR}`).
 - `PROVIDES` - A list of recipes provider names. This will set the relationship between target and recipe. If setting this option, the recipe can be called by using on of the provider names.
 - `SPECIAL_PKGSUFFIX` - This will define some suffixes, which should be removed when referring to the `BPN` (base package name). For example when extending a recipe with cross compile support this cross version of the recipe is also extended with the `-cross` suffix.

 - `BPN` - Package name with all suffixes defined with `SPECIAL_PKGSUFFIX` removed.
 - `BP` -  Addition of base package name and package version (`${BPN}-${PV}`).
 - `DATE` - Date of today (YYYYMMDD).
 - `TIME` - Current time (HHMMSS).
 - `DATETIME` - Addition of `Date` and `TIME` (`${DATE}${TIME}`).
 - `PARALLEL_MAKE` - Number of parallel make instances.
 - `SUDO` - Sudo command prefix. The actual command will follow after the `SUDO` (e.g ${SUDO} ls).
 - `PP` - The recipes workdir within the chroot, pointing to `/home/builder/${PN}`
 - `PPS` - The recipes source directory within the chroot, pointing to `${PP}/${SRC_DIR}`.
 - `PPB` - The recipes build directory within the chroot, pointing to `${PP}/${BUILD_DIR}`.
 - `CHROOT` - The chroot command used when running chroot tasks.

 - `BUILDCHROOT_ID` - Chroot identifier for the buildchroot.
 - `CROSS_BUILDCHROOT_ID` - Chroot identifier for the cross-buildchroot.
 - `ROOTFS_ID` - Chroot identifier for the final target rootfs.

 - `SCHROOT_ID` - Current chroot identifier. Setting this will set the chroot identifier for the chroot task defined.
 - `DEB_SIGN` - Commandline options specific for signing, when runnig `dpkg-builpackage`.
 - `DEB_COMPRESSION` - Compression type for generating the original source file when running `dpkg-buildpackage`.
 - `DEB_HOST_ARCH` - The build host architecture. This version of Isar autodetects the host arch, but you can overwrite it.
 - `APT_EXTRA_OPTS` - Extra options when running apt command in Isar.

 - `ROOTFS_IMAGE_SIZE` - Size of the rootfs partitions. Multipliers k, M ang G can be used.
 - `SKIP_APPEND_CROSS_SUFFIX` - Prevent all existent items from beeing suffixed with `-cross`, when supporting cross build.
 - `SKIP_APPEND_NATIVE_SUFFIX` - Prevent all existent items from beeing suffixed with `-native`, when supporting native build