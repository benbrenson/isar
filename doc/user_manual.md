# ISAR User Manual

## Contents
 - [Introduction](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#introduction)
 - [Getting Started](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#getting-started)
 - [Terms and Definitions](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#terms-and-definitions)
 - [How Isar Works](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#how-isar-works)
 - [General Isar Configuration](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#general-isar-configuration)
 - [Isar Distro Configuration](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#isar-distro-configuration)
 - [Custom Package Compilation](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#custom-package-compilation)
 - [Image Type Selection](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#image-type-selection)
 - [Add a New Layer](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#add-a-new-layer)
 - [Add a New Distro](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#add-a-new-distro)
 - [Add a New Machine](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#add-a-new-machine)
 - [Add a New Image](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#add-a-new-image)
 - [Add a New Image Type](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#add-a-new-image-type)
 - [Add a Custom Application](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#add-a-custom-application)
 - [Add a New Kernel](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#add-a-new-kernel)
 - [Dependency management](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#dependency-management)
 - [Running chrooted tasks](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#running-chrooted-tasks)
 - [Navigation through directories under tmp](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#navigation-through-directories-under-tmp)
 - [Troubleshooting](https://github.com/benbrenson/isar/blob/master/doc/user_manual.md#troubleshooting)
 - [Varibles glossary](https://github.com/benbrenson/isar/blob/master/doc/variables.md)
 - [Linux Image Update](https://github.com/benbrenson/isar/blob/master/doc/linux_image_update.md)


## Introduction
Isar is a set of scripts for building software packages and repeatable generation of Debian-based root filesystems with customizations.

Isar provides:
 - Fast target image generation: About 20 minutes to get base system image for one machine.
 - Use any apt package provider, including open-source communities like `Debian`, `Raspbian`, etc. and proprietary ones created manually.
 - Native compilation: Packages are compiled in a `chroot` environment using the same toolchain and libraries that will be installed to the target filesystem.
 - Product templates that can be quickly re-used for real projects.


### Isar fork additional features:
 - Cross compilation of resource intensive source packages (e.g. QT, linux-kernel etc.)
 - Debianizing of non Debian compatible source code repositories.
 - Defining bitbake shell tasks, which are running in chrooted environments. This abstracts a lot of complexity related to chrooted tasks and will
 add support of layering those defined tasks.
 - Build images with docker.
 - Linux Firmware update with swupdate (meta-swupdate required).
 - Support for reproducible builds (by caching all fetched debian packages).


---

## Getting Started
The steps below describe how to build the images provided by default.

### Install Host Tools
Install the following packages on the build host system:
```
dosfstools
git
mtools
multistrap
parted
e2fsprogs
python3
qemu
qemu-user-static (>= 2.8)
sudo
schroot
mtd-utils
util-linux
dh-make
u-boot-tools
bc
device-tree-compiler
quilt
devscripts
aptly (>= 1.2)
```

When running docker based builds, the following packages should also be installed:
```
docker-compose
docker
```

**Notes:**
* BitBake requires Python 3.4+.
* The python3 package is required for the correct `alternatives` setting.
* qemu-user-static should be higher or equal than 2.8, because this version supports propper multithreading support.
  * Otherwise the build will fail arbitrarily at rootfs creation time with qemu `core dumped` errors.

### Setup non interactive Sudo
Isar requires `sudo` rights without password to work with `chroot` and `multistrap`. To add them, use the following steps:

    ```
    $ visudo
    ```

In the editor, allow the current user to run sudo without a password, e.g.:

    ```
    <user>  ALL=NOPASSWD: ALL
    ```

Replace `<user>` with your user name. Use the tab character between the user name and parameters.

### Check out Isar and required meta-layers
This section describes how to fetch and prepare the build environment by your own.

    ```
    $ BUILDDIR="build-relase"
    $ mkdir ebs-isar

    $ cd ebs-isar

    $ mkdir sources
    $ cd sources

    $ git clone https://github.com/benbrenson/isar.git isar
    $ git clone https://github.com/benbrenson/meta-sunxi.git meta-sunxi
    $ git clone https://github.com/benbrenson/meta-swupdate.git meta-swupdate
    $ git clone https://github.com/benbrenson/meta-unittest.git meta-unittest

    ```
**Note: Layer meta-unittest will fetch sources, which are not open-source, yet.**

**Note: If some repositories are only reachable via https, you need to provide the required credentials via git-credentials:**

    ```
    $ git config --global credential.helper store
    $ echo "https://<username>:<password>@<git url>" >> ~/.git-credentials
    ```

### Initialize the Build Directory
The main parts of setting up the build directory where already done at the last step.
Now the following have to be done:

    ```
    $ BUILDDIR="build-relase"
    $ cd ebs-isar
    $ cp sources/isar/scripts/setup-environment .
    $ source setup-environment $BUILDDIR
    ```

After running the `setup-environment` script, the build directory is filled with default config files, and your shell does cd into the build directory.

Now the created isar directory should look as follows:
```
ebs-isar
├── setup-environment
├── build-release
│   ├── conf
│   └── docker
└── sources
    ├── isar
    ├── meta-sunxi
    ├── meta-swupdate
    └── meta-unittest
```

Before running any bitbake task, please check the `local.conf` file under `BUILDDIR/conf` for proper settings. At least following settings have to be configured:

    ```
    MACHINE ??= "nanopi-neo"          # or "nanopi-neo-air"
    DEB_EMAIL="your.email@email.com"
    DEB_FULLNAME="Your Name"
    ```


### Build Images (without docker)
The following command will produce `isar-image-base` image:

    ```
    $ bitbake multiconfig:nanopi:isar-image-base
    ```

**Note:** For now only nanopi images are possible to build.

### Build images (with docker)

    ```
    $ cd docker
    $ docker-compose up
    ```

To build just for one target, pass only its name to `bitbake`.


### Reproducible builds
Since Isar will fetch all debian packages from the official repositories, you will not be able to know at which time
a package is getting updated at the remote repository. This can lead to different package versions in subsequent builds.
Therefore Isar is making use of a local apt repository, which is stores all debian packages after the very first build for
a specific machine type.

Each subsequent build will fetch all packages from the local repository rather than from the remote repository.
You can also control if the apt cache should be activated or not with the `REPRODUCIBLE_BUILD_ENABLED` variable, which
is turned on ("1") in default.

To turn it off, you have to set it within the `local.conf` configuration file to "0".
A tool called **"aptly"** is used for the core functionality of the apt cache. For further information please
take a look into man page of aptly.

---

## Terms and Definitions

### Chroot
`chroot`(8) runs a command within a specified root directory. Please refer to GNU coreutils online help: <http://www.gnu.org/software/coreutils/> for more information.

### QEMU
QEMU is a generic and open source machine emulator and virtualizer. Please refer to <http://wiki.qemu.org/Main_Page> for more information.

### Debian
Debian is a free operating system for your machine. Please refer to <https://www.debian.org/index.en.html> for more information.

### Apt
`Apt` (for Advanced Package Tool) is a set of tools for managing Debian package repositories and applications installed on your Debian system. Please refer to <https://wiki.debian.org/Apt> for more information.

### BitBake
BitBake is a generic task execution engine for efficient execution of shell and Python tasks according to their dependencies. Please refer to <https://www.yoctoproject.org/docs/1.6/bitbake-user-manual/bitbake-user-manual.html> for more information.

---

## How Isar Works
Isar workflow consists of stages described below.

### Generation of  Buildchroot Filesystem
This filesystem is used as a build environment to compile custom packages. It is generated using `apt` binaries repository, selected by the user in configuration file. Please refer to distro configuration chapter for more information.

### Custom Package Compilation
During this stage Isar processes custom packages selected by the user and generates binary `*.deb` packages for the target. Please refer to custom packages compilation section for more information.

### Generation of Basic Target Filesystem
This filesystem is generated similarly to the `buildchroot` or `crossbuildchroot` one using the `apt` binaries repository. Please refer to distro configuration chapter for more information.

### Install Custom Packages
At this stage, Isar populates target filesystem by custom packages that were built in previous stages.

### Target Image Packaging
Isar can generate various image types, e.g. an ext4 filesystem or a complete SD card image. The list of images to produce is set in configuration file, please refer to image type selection section.

---

## General Isar Configuration
Isar uses the following configuration files:
 - conf/local.conf
 - conf/bblayers.conf
 - conf/bitbake.conf
 - conf/multiconfig/<board>.conf

`local.conf` defines some default variable values (e.g. for ${MACHINE} and ${DISTRO}). It also contains global definitions for bitbake.


`bitbake.conf` defines global definitions for bitbake.

`<board>.conf` defines the ${MACHINE} and ${DISTRO} variable values and overwrites these values in local.conf. The config file is loaded after specifying it with bitbake multiconfig:board:<target>.


### bblayers.conf
This file contains the list of meta layers, where `bitbake` will search for recipes, classes and configuration files.

### local.conf
This file contains variables that will be exported to `bitbake` environment and will be processed in recipes. The default Isar configuration uses the following variables:

 - `BBMULTICONFIG` - The list of the machines to include the respective configuration files. If this option is omitted, user has to manually define the pair `MACHINE`/`DISTRO` for specific target.
 - `IMAGE_INSTALL` - The list of custom packages to build and install to target image, please refer to relative chapter for more information.
 - `BB_NUMBER_THREADS` - The number of `bitbake` jobs that can be run in parallel. Please set this option according your host CPU cores number.
 - `PARALLEL_MAKE` - Number of parallel makefile instances. Make should be called with -j${PARALLEL_MAKE}
 - `DEB_EMAIL` - The eMail address used by dpkg-buildpackage.
 - `DEB_FULLNAME` - The name used by dpkg-buildpackage.
 - `DEB_HOST_ARCH` - The build host architecture. This version of Isar autodetects the host arch, but you can overwrite it.
 - `IMAGE_REVISION` - Only required when swupdate is also integrated as linux update mechanism. This variable is needed by swupdate for detecting the board it will run on.
 - `BROKER_IP` - Only required when running swupdate with the python update service, which in turn is required to receive MQTT messages from a update server/broker.
 - `BROKER_PORT` - See `BROKER_IP`.
 - `UPDATE_TOPIC` - The topic on which the update service will subscribe to, in order to receive update messages from the update server/broker.
 - `IMAGE_FEATURES`- Additional image features (e.g. systemd support or installing a lot of debugging tools on the target).

### bitbake.conf
This file contains the global definitions for all bitbake recipes and classes. This file also includes the `conf/distro/${DISTRO}.conf` and `conf/machine/${MACHINE}.conf` files located in respective layer directories.


---

## Isar Distro Configuration
In Isar, each machine can use its specific Linux distro to generate `buildchroot`, `cross-buildchroot` and target filesystem. By default, Isar provides configuration files for the following distros:
 - debian-wheezy
 - debian-sid
 - debian-jessie
 - debian-stretch
 - raspbian-stable

User can select appropriate distro for specific machine by setting the following variable in local.conf (in acase of multiconfig is not used):
```
DISTRO = "distro-name"
```

---

## Custom Package Compilation
Isar provides possibility to compile and install custom packages. The current version supports building `deb` packages using `dpkg-buildpackage`, so the sources should contain the `debian` directory with necessary meta information. It is also possible to provide a debian directory with a `control` and `rules` file, at the recipes folder(at least the control file template is required).


To add new package to image, it needs the following:
 - Create package recipe and put it in your layer.
 - Append `IMAGE_INSTALL` variable by this recipe name. If this package should be included for all the machines globally, put `IMAGE_INSTALL` to `local.conf` file. If you want to include this package for specific machine, put it to your machine configuration file.

Please refer to `add custom application` section for more information about writing recipes.

---

## Image Type Selection
Image are generated by defining a *.wks kickstart file. This kickstart file in turn is interpreted by the image creation tool called wic.
The image recipe has to inherit the ```debian-image``` bbclass, in order to run tasks related to image creation.



---

## Add a New Layer
When adding a new layer first of all you have to think about what your layer will support and what it will be used for.
The open-embedded community offers a [guideline](https://www.yoctoproject.org/docs/1.8/dev-manual/dev-manual.html#understanding-and-creating-layers), which describes all possible layers and for what purpose each layer exists.
**Isar should follow the same convention as yocto does!**
For information please refer to the yocto dev-manual.

Layers allow you to isolate different types of customizations from each other. You might find it tempting to keep everything in one layer when working on a single project. However, the more modular your Metadata, the easier it is to cope with future changes.

To illustrate how layers are used to keep things modular, consider machine customizations. These types of customizations typically reside in a special layer, rather than a general layer, called a Board Support Package (BSP) Layer. Furthermore, the machine customizations should be isolated from recipes and Metadata that support a new GUI environment, for example. This situation gives you a couple of layers: one for the machine configurations, and one for the GUI environment. It is important to understand, however, that the BSP layer can still make machine-specific additions to recipes within the GUI environment layer without polluting the GUI layer itself with those machine-specific changes. You can accomplish this through a recipe that is a BitBake append (.bbappend) file, which is described later in this section.



---

## Add a New Distro
The distro is defined by the set of the following variables:

 - `DISTRO_SUITE` - Repository suite like stable, jessie, wheezy etc.
 - `DISTRO_ARCH` - Machine CPU architecture.
 - `DISTRO_COMPONENTS` - Repository components like main, contrib, non-free etc.
 - `DISTRO_APT_SOURCE` - Repository URL.
 - `DISTRO_KEYRINGS` - Keyring packages needed by multistrap to achieve secure repository authentication.

Below is an example for debian stretch:
```
DISTRO_SUITE ?= "stretch"
DISTRO_ARCH ?= "armhf"
DISTRO_COMPONENTS ?= "main contrib non-free"
DISTRO_APT_SOURCE ?= "http://deb.debian.org/debian"
DISTRO_KEYRINGS ?= "debian-archive-keyring"
```

To add new distro, user should perform the following steps:
 - Create `distro` folder in your layer:

    ```
    $ mkdir meta-user/conf/distro
    ```

 - Create the `.conf` file in distro folder with the name of your distribution. We recommend to name distribution in the following format: `name`-`suite`, for example:

    ```
    debian-wheezy
    debian-jessie
    ```
 - This file must have the same name as set in ${DISTRO} defined in the conf/multiconfig/*.conf file.
 - In this file, define the variables described above.
 - Do not include board dependent things within this file, except ${DISTRO_ARCH}.

---

## Add a New Machine
Adding a new machine is usually done by creating a new BSP layer. If a new machine is added to a persistent BSP layer, only a new `<MACHINE>`.config has to be added.
Every machine is described in its configuration file. The file defines the following variables:

 - `FIX_KVERSION` - Complete kernel version. This can be extracted from the kernel makefile. Required for running **depmod** within the rootfs, since kernel recipe doesn't contain complete version (e.g. -rc5 is missing). The current version of Isar automatically extracts kernel version from the kernel makefile, so setting this variable is not mandatory anymore.
 - `PREFERRED_PROVIDER_virtual/kernel` - Set the kernel recipe name which will be used for the current machine.
 - `PREFERRED_VERSION_virtual/kernel` - Set the kernel recipe version.
 - `PREFERRED_PROVIDER_virtual/bootloader` - Set the bootloader recipe name which will be used for the current machine.
 - `PREFERRED_VERSION_virtual/bootloader` - Set the bootloader recipe version.
 - `KERNEL_CMDLINE` - Kernel commandline substituted within uboots bootscript.
 - `TARGET_ARCH` - Some buildsystems (e.g. Kconfig) need architecture specific settings for this type of machine.
 - `TARGET_PREFIX` - Sets the cross compiler prefix for this machine.
 - `KIMAGE_TYPE` - The name of kernel binary that it installed to `/boot` folder in target filesystem. This variable is used by isar for determing which
 image type has to be compiled by the kernel.
 - `MACHINE_SERIAL` - The name of serial device that will be used for console output.
 - `IMAGE_TYPES` - The type of images to be generated for this machine (e.g. sdcard).
 - `DTBS` - The primary device tree file. Isar will install this device tree to the location specified with ${DTB_INSTALL_DIR}.
 - `DTBOS` - Device tree overlay files. The kernel has to be capable of compiling device tree overlays, when adding device tree overlays to this variable.
 - `BOOT_IMG` - The name of the uboot image. Isar will also build a complete debian package for uboot.
 - `IMAGE_BOOT_FILES` - When setting this variable, only the specified files will be copied into the boot partition. When not set, the whole content of
 the /boot folder will be copied. The semicolon separates files and has following meaning: **source;destination**.
 - `UIMAGE_LOADADDR` - The uImage loadaddress. Only required if ${KIMAGE_TYPE} is uImage.
 - `TARGET_ARCH` - The target architecture required by different buildsystems (e.g. Kconfig). Please do not set a debian specific architecture type here.
 - `BOOT_DEVICE` - Name of the boot device (e.g. mmc). This version of Isar only supports mmc devices, yet.
 - `BOOT_DEVICE_LINUX` - The Linux device where the system boots from.
 - `ROOT_DEVICE_LINUX` - The Linux device where the system has its root partition on.
 - `BOOT_DEVICE_NUM` - Number or interface identifier, interpreted by uboot commands.
 - `BOOTP_PRIM_NUM` - Number of the primary boot partition. This will set the primary boot partition on the first boot by uboot.
 - `BOOTP_SEC_NUM` - Number of the secondary boot partition. This will set the secondary boot partition on the first boot by uboot.
 - `ROOTP_PRIM_NUM` - Interface for the primary rootfs partition, interpreted by the linux kernel on the kernel cmdline. This variable is also used to detect the partition which should be updated. So when for example the /dev/mmcblk0p1 device is used, `ROOTP_PRIM_NUM` has to be set to 1.
 - `ROOTP_SEC_NUM` - Interface for the secondary rootfs partition, interpreted by the linux kernel on the kernel cmdline. This variable is also used to detect the partition which should be updated. So when for example the /dev/mmcblk0p1 device is used, `ROOTP_PRIM_NUM` has to be set to 1.
 - `RECOVERY_BOOTPART_NUM` - Set the partition where the recovery files reside.


Below is an example of machine configuration file for `NanoPi-Neo` board:
```
PREFERRED_PROVIDER_virtual/kernel = "linux-image-sunxi-cross"
PREFERRED_VERSION_virtual/kernel = "4.13"
PREFERRED_PROVIDER_virtual/bootloader = "u-boot-sunxi-cross"
PREFERRED_VERSION_virtual/bootloader = "2017.13"

KIMAGE_TYPE="uImage"
KERNEL_CMDLINE="console=${MACHINE_SERIAL},115200 console=tty1 rw rootwait panic=10"

UIMAGE_LOADADDR="0x40008000"
DTBS="sun8i-h3-nanopi-neo.dtb"
DTBOS="sun8i-h3-i2c0.dtbo \
          sun8i-h3-i2c1.dtbo \
          sun8i-h3-i2c2.dtbo \
          sun8i-h3-spi-mcp2515.dtbo \
          sun8i-h3-sc16is760.dtbo \
          sun8i-h3-spi-w5500.dtbo \
          sun8i-h3-spi-spidev.dtbo \
         "

DTBOS_LOAD = "${DTBOS}"
DTBOS_LOAD_remove = "sun8i-h3-spi-spidev.dtbo sun8i-h3-i2c2.dtbo"


BOOT_IMG = "u-boot-sunxi-with-spl.bin"
BOOTSCRIPT = "boot.scr"
IMAGE_BOOT_FILES = "${BOOTSCRIPT} ${KIMAGE_TYPE} dts/${DTBS};${DTBS}"

MACHINE_SERIAL = "ttyS0"

IMAGE_FSTYPES = "sdcard sdcard-redundant"

# Set further target architecture specifics
TARGET_ARCH="arm"
TARGET_PREFIX="arm-linux-gnueabihf"

# Using for interface compatibility
DEB_ARCH="${DISTRO_ARCH}"

# Device from which to boot from
BOOT_DEVICE = "mmc"
BOOT_DEVICE_LINUX = "mmcblk0p"
ROOT_DEVICE_LINUX = "${BOOT_DEVICE_LINUX}"
BOOTDEVICE_FSTYPE = "vfat"

# Boot device identifiers required by u-boot
# Number of the boot device
BOOT_DEVICE_NUM="0"

# Partition number of boot partitions
BOOTP_PRIM_NUM = "1"
BOOTP_SEC_NUM = "2"

# Partition number of rootfs partitions
ROOTP_PRIM_NUM = "2"
ROOTP_SEC_NUM = "3"

```

To add a new machine, user should perform the following steps:
 - Create the `machine` directory in your layer:

    ```
    $ mkdir meta-user/conf/machine
    ```

 - Create `.conf` file in machine folder with the name of your machine.
 - Define all variables, that where described above in this chapter.
 - The machine configuration file should only define machine specific variables, which in turn means describing hardware dependent properties like kernel, bootloader, boot and rootfs partition identifiers and firmware packages.

---

## Add a New Image
Image in Isar contains the following artifacts:
 - Image recipe - Describes set of rules how to generate target image.
 - `Multistrap` configuration file - Contains information about distro, suite, `apt` source etc.

### General Information
The image recipe in Isar creates a folder with the target root filesystem. The default location is:
```
tmp/rootfs/${MACHINE}
```
Isar uses the openembedded tool called **wic** for creating bootable rootfs images.
For describing the partition layout for images, wic in turn uses so called **kickstart** files.
Those kickstart files will be generated from isar out of the `image_layout.json` file.
The image_layout file describes the partitioning of a single image type.
So what isar does for each type in `ÌMAGE_TYPES` is to look which partitions are available in the
layout_image.json file.
For each described partition, a single partition image will be created, and then
a complete bootable image will be created out of those partition images.
All attributes like size, filesystem type, label and mountpoint where specified within the json file.

There are two things to be done in order to create new images:
1. Create new image_layout.json file (or copy a persistent one). This file must be located by the image recipes search folder, so setting the FILESPATH variable must be done.
2. Add your image type (e.g. sdcard image) to the `IMAGE_TYPES` variable to the machine configuration file.


Currently supported filesystem types are:
* ext2/3/4
* vfat

Currently supported image types are:
* sdcard (simple sd card image with two partitions: boot, rootfs)
* sdcard-redundant(same as sdcard but containing two equal rootfs partitions)

**Note: No flash filesystems are supported (e.g. ubifs or jffs), yet.**


### Create a new Custom Image
**new_image.bb:**
```
inherit debian-image

FILESPATH_prepend := "${THISDIR}/${PN}-${PV}:${THISDIR}/files:"

# Additional packages to install (from debian repositories)
IMAGE_PREINSTALL += " openssh-server "

# Additional packages to install (from other recipes)
IMAGE_INSTALL += " linux-image-cross u-boot-cross "
```


**image_layout.json:**
```
{
    "partitions" : {

        "rootfs" : {
            "type" : "rootfs",
            "label" : "root_prim",
            "mountpoint" : "/",
            "filesystem" : "ext4",
            "size" : -1,
            "num" : 0

        },

        "rootfs_sec" : {
            "type" : "rootfs",
            "label" : "root_sec",
            "mountpoint" : "/",
            "filesystem" : "ext4",
            "size" : -1,
            "num" : 1

        },

        "recovery" : {
            "type" : "bootimg-partition",
            "label" : "recovery",
            "mountpoint" : "/boot/recovery",
            "filesystem" : "vfat",
            "size" : -1,
            "num" : 2
        },

        "update" : {
            "type" : "rootfs",
            "label" : "update",
            "src-dir" : "UPDATE_DIR",
            "mountpoint" : "/update",
            "filesystem" : "ext4",
            "size" : -1,
            "num" : 3

        }

    }
}
```
Each partition of the `image_layout.json` file contains following attributes:

- `type` - Set the type of partition content. This will in turn select the proper source plugin for WIC. The type `rootfs` is required for simple filesystem images, whose data will be copied out of the `ROOTFS_DIR` folder. The `bootimg-partition` type is needed when you don't copy the complete rootfs folder, but instead you choose single files or folders with the `IMAGE_BOOT_FILES` variable.
- `label` - Set the filesystem label for a partition.
- `src-dir` - When using the `rootfs` type, this variable will change the folder from which data will be copied. Default is `ROOTFS_DIR`.
- `mountpoint` - Selects the mountpoint within the image.
- `filesystem` - Selects the filesystem for this partition. For each partition a filesystem image will be generated by isar.
- `size` - The minimal size of the filesystem. When -1 is selected, the size is calculated automatically by WIC.
- `num` - This will set the order of all partitions, the partitions will be created in ascending order.



**Note: No flash filesystems are supported (e.g. ubifs or jffs), yet.**

### Create a new image based on isar-image-base (prevered way)
The `isar-image-base` recipe provides a basic image, from which a new custom image can inherit.
When you want to reuse functionalities of the `ìsar-image-base` image, you can also inherit the base image and extend it with your needs:
The base image can be inherited like follows:

new_image.bb:
```
require ${BSPDIR}/sources/isar/meta-isar/recipes-core/images/isar-image-base.bb
.
.
.
custom stuff (adding packages, do stuff after rootfs generation etc.)
.
.
.
```

### Last steps (rootfs customizations at the end)
As already mentioned, Isar uses `bitbake`to accomplish the work. The whole build process is a sequence of tasks. This sequence is generated using task dependencies, so the next task in chain requires completion of previous ones.
The very last tasks when building the image are processed for tasks defined by the `POST_ROOTFS_TASKS` variable.
So if you want to customize the rootfs at the very last moment of creation, you can add all required tasks to this variable.
```
do_foo(){
    do something
}

POST_ROOTFS_TASKS += "do_foo;"
```
Those tasks are also able to be executed in chroot context.

**Note: These tasks can only be run when defining them within the scope of the image recipe.**

### Package tunes
The package tunes mechanism is basically a standart for customizing packages, which are getting installed from main repositories, and is for now in a development state.

The main meaning lies in adding a bunch of package customizations, which where only appended/completed, when the associated package is actually included and skipped otherwise.
For now all package tunes will be handled, but a warning message is displayed in case of not finding an affiliated entry in `IMAGE_INSTALL` or `IMAGE_PREINSTALL`.


---

## Add a Custom Application
The isar buildsystem is capable of compiling software and creating debian compatible packages.
But there are different ways in how the packages can be compiled:

* Target compiling in a chrooted qemu emulated environment (No cross compile complexity at the expense of performance).
* Target cross compiling in chrooted cross build environment (Best performance at the expense of cross compile complexity).
* Native host architecture compiling (e.g. for compiling host machine tools).

The next thing is, Isar **is only capable of compiling already debian compatible packages**, implying that all software repositories shall either already contain
all debian specific settings, or otherwise extend the non debian software package by debianizing it with Isar.
So if the package is not debian compatible, it has to be debianized first!

But what is a debian compatible package?
A debian compatible package is a piece of software, which already contains the required ```debian folder``` with all debian specific metadata
(rules, control file etc.)
The main steps for creating, debian custom applications is as follows:

* Download the software
* Debianize (if not debian compatible sources)
* Compile the software and create a debian package
* Install the debian package into the debian deploy folder (`DEPLOY_DIR_DEB`)

Before creating new recipe it's highly recommended to take a look into the BitBake user manual mentioned in Terms and Definitions section.

The easiest recipe for getting a source fetched, compiled and installed is the following:
```
DESCRIPTION = "Sample application for ISAR"

inherit dpkg

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

SRC_URI = "git://github.com/ilbers/hello.git"
SRCREV = "ad7065ecc4840cc436bfcdac427386dbba4ea719"

SRC_DIR = "git"
```
This recipe will fetch an already debian compatible source and compiles it in a qemu emulated chroot environment.
As can be seen here, there is not much to do in this case.


### Native compilation
Isar supports native compilation of software packages. This type of compiling may be helpful when tools, running on the host machine, are required.
By adding the `BBCLASSEXTEND = "native"` setting, the recipe will add the native compilation support for a recipe.
Adding this feature will create a second virtual version of the recipe.

One version running with target compilation and a another version running with native compilation.
In order to run the native version, the recipe has to be called with `<recipe-name>-native`.

**Note:** Distinctions between target or native compilation lies in the hands of the recipe developer. Dependent on the recipes compilation mode
someone may set different compiler flags or something else.
This can be done by appending the `_class-native` suffix to a variable or function.


As a theoretical scenario, let's assume, the Isar example recipe, needs to be compiled for the build host architecture.
Then it should look like follows:

```
DESCRIPTION = "Sample application for ISAR"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

inherit dpkg

PV = "1.0"

SRC_URI = "git://github.com/ilbers/hello.git"
SRCREV = "ad7065ecc4840cc436bfcdac427386dbba4ea719"

SRC_DIR = "git"

EXAMPLE_VARIABLE_class-native = "CROSS_EXAMPLE"

BBCLASSEXTEND = "native"
```


### Cross compilation
Isar supports cross compilation of software packages. This type of compiling may be helpful when tools, running on the host machine, are required.
By adding the `BBCLASSEXTEND = "cross"` setting, the recipe will add the cross compilation support for a recipe.
Adding this feature will create a second virtual version of the recipe.

One version running with target compilation and a another version running with cross compilation.
In order to run the cross version, the recipe has to be called with `<recipe-name>-cross`.

**Note:** Distinctions between target or cross compilation lies in the hands of the recipe developer. Dependent on the recipes compilation mode
someone may set different compiler flags or something else.
This can be done by appending the `_class-cross` suffix to a variable or function.


As a theoretical scenario, let's assume, the Isar example recipe, needs to be compiled for the target architecture.
Then it should look like follows:

```
DESCRIPTION = "Sample application for ISAR"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

inherit dpkg

PV = "1.0"

SRC_URI = "git://github.com/ilbers/hello.git"
SRCREV = "ad7065ecc4840cc436bfcdac427386dbba4ea719"

SRC_DIR = "git"

EXAMPLE_VARIABLE_class-cross = "CROSS_EXAMPLE"

BBCLASSEXTEND = "cross"
```

### Target compilation
This example was already shown as easiest recipe.


### Debianize the sources
As already mentioned at the introduction, Isar is only capable of compiling debian compatible sources. But there are a lot of software repositories out there,
containing no support for debian package based compilation.
Therefore Isar has support for debianizing those packages, before compiling them.

At least the following things have to be done in order to add debianizing:

* Add the debian folder at `files` directory of the associated package.
* Add at least the `control` file template to the debian folder.
* Inherit the `debianize` class in the recipe.
* Add a debian `rules` makefile or generate it by implementing all rule targets in the recipe.
* Define `URL` variable.
* Define `SECTION` variable.
* Define `PRIORITY` variable.

So this may be the minimal setup for debianizing software sources in order to run Isar without complaining about something missing when debianizing the package.
Of course further customizations are possible, by adding those to the debian folder (e.g. man pages, post/preinstal scripts etc.).

The control file template shall look like follows:
```
Source: ##PACKAGE_BASE##
Section: ##SECTION##
Priority: ##PRIORITY##
Maintainer: ##MAINTAINER##
Build-Depends: ##DEPENDS##
Standards-Version: 3.9.6
Homepage: ##URL##

Package: ##PACKAGE##
Architecture: ##DEB_ARCH##
Description: ##DESCRIPTION##
Depends: ##RDEPENDS##
```

It is also possible to create different binary packages for one source package. For example when a package provides both binaries and runtime libraries or header files. In this case the debian way tells us to create also *-dev packages. Then a control file template should look as follows:

```
Source: ##PACKAGE_BASE##
Section: ##SECTION##
Priority: ##PRIORITY##
Maintainer: ##MAINTAINER##
Build-Depends: ##DEPENDS##
Standards-Version: 3.9.6
Homepage: ##URL##

Package: ##PACKAGE##-dev
Architecture: ##DEB_ARCH##
Description: ##DESCRIPTION_DEV##
Depends: ##RDEPENDS##
```

Don't forget to add substitutions for the *-dev package into the recipe:
```
do_generate_debcontrol_append() {
    sed -i -e 's/##DESCRIPTION_DEV##/${DESCRIPTION_DEV}/g' ${CONTROL}
}
```

For more information about debian background or how to create debian packages, see [here](https://www.debian.org/doc/manuals/maint-guide).

#### Use already created rules file
As a theoretical scenario, let's assume, the Isar example recipe, needs to be debianized (and cross-compiled) and a rules file as well as the control file are already contained.
Then it should look like follows:
```
DESCRIPTION = "Sample application for ISAR"

LICENSE = "gpl2"

RULE_EXIST = "true"
inherit dpkg debianize


PV = "1.0"

URL = "git://github.com/ilbers/hello.git"
SRC_URI = " ${URL}\
           file://debian \
          "

SRCREV = "ad7065ecc4840cc436bfcdac427386dbba4ea719"

SRC_DIR = "git"
SECTION = "utils"
PRIORITY = "optional"

EXAMPLE_VARIABLE_class-cross = "CROSS_EXAMPLE"

BBCLASSEXTEND = "cross"
```

**Note: The RULES_EXIST variable disables generation of the rules file.**

#### Generate the rules file
Debians rules makefile implements a lot of functionality and possible configuration options. It contains the following main targets:

* clean: to clean all compiled, generated, and useless files in the build-tree. (Required)
* build: to build the source into compiled programs and formatted documents in the build-tree. (Required)
* build-arch: to build the source into arch-dependent compiled programs in the build-tree. (Required)
* build-indep: to build the source into arch-independent formatted documents in the build-tree. (Required)
* install: to install files into a file tree for each binary package under the debian directory. If defined, binary* targets effectively depend on this target. (Optional)
* binary: to create all binary packages (effectively a combination of binary-arch and binary-indep targets). (Required)
* binary-arch: to create arch-dependent (Architecture: any) binary packages in the parent directory. (Required)
* binary-indep: to create arch-independent (Architecture: all) binary packages in the parent directory. (Required)

All targets have already been implemented in the `debianize` class, and must be overwritten if needed.

The `build` as well as `install` targets are the most important ones, which always should be overwritten, by considering the packages' buildsystem information (make, autotools, cmake etc.).
For now there are no proper default tasks making use of different buildsystems, implemented. This will be added in the future


As a theoretical scenario, let's assume, the Isar example recipe, needs to be debianized and the rules file will be generated out of recipe tasks.
Then it should look like follows:

```
DESCRIPTION = "Sample application for ISAR"

LICENSE = "gpl2"

inherit dpkg debianize

PV = "1.0"

URL = "git://github.com/ilbers/hello.git"
SRC_URI = " ${URL}\
           file://debian \
          "
SRCREV = "ad7065ecc4840cc436bfcdac427386dbba4ea719"

SRC_DIR = "git"
SECTION = "utils"
PRIORITY = "optional"

debianize_build[target] = "build"
debianize_build() {
    @echo "Running build target."
    make -j${PARALLEL_MAKE}
}

debianize_install[target] = "install"
debianize_install[tdeps] = "build"
debianize_install() {
    @echo "Running install target."
    dh_testdir
    dh_testroot
    dh_clean  -k
    install -m 755 -d debian/${BPN}/etc
    install -m 755 ${PPS}/example_file debian/${BPN}/etc/example_file
}
```
Some variables may be worth a short explanation:

- `[target]` - Sets the name of the Makefile target.
- `[tdeps]` - Sets dependencies from which the target is dependent from.

For the settings
```
debianize_install[target] = "install"
debianize_install[tdeps] = "build"
debianize_install() {
    echo "foo"
}
```
the Makefile representation will look like this:
```
install: build
    echo "foo"
```


#### Generate the rules file for python applications
A special class was implemented for supporting python based debian packages. All default tasks/target are already implemented, when
inheriting from `debianize-python`.
The following recipe shows a basic example:
```
DESCRIPTION = "Python mqtt client library."
LICENSE = "gpl"

inherit dpkg debianize-python

URL = "https://pypi.python.org/packages/33/7f/3ce1ffebaa0343d509aac003800b305d821e89dac3c11666f92e12feca14/paho-mqtt-1.3.0.tar.gz"

SRC_DIR = "paho-mqtt-${PV}"
SRC_URI[sha256sum] = "2c9ef5494cfc1e41a9fff6544c5a2cd59ea5d401d9119a06ecf7fad6a2ffeb93"
SRC_URI[md5sum] = "b9338236e2836e8579ef140956189cc4"

SRC_URI += "${URL} \
            file://debian \
           "

SECTION = "python"
PRIORITY = "optional"
```

## Add a New Kernel
Adding a kernel can be done in two ways. Either you select the kernel image from the official debian repositories related to your hardware, or you create a own recipe to compile a custom version of the kernel image.

In the former case, you only have to add the kernel package name to the `IMAGE_PREINSTALL` variable in the image recipe.


If you want to make use of an custom kernel from another repository of yourself, you have to add a kernel recipe.
The file defines the following important variables:
- `DTBO_SRC_DIR` - When using device tree overlay files, this variable will define the location where isar can find those files for installing them later to the image. Those files where copied to this location before (see do_copy_device_tree() task).
- `DTBO_DEST_DIR` - This will set the final destination within the rootfs image, where the device tree overlays where installed.

The following example will show how that can be achieved:

```
DESCRIPTION_nanopi ?= "Mainline linux kernel support for the nanopi."

DESCRIPTION_nanopi-neo-air = "Mainline linux kernel support for the nanopi-neo-air."

inherit debianize kernel
DEPENDS = "dtc-native"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}-${PV}:"

URL = "git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git"
BRANCH="master"
SRCREV = "ef954844c7ace62f773f4f23e28d2d915adc419f"

SRC_DIR = "git"
SRC_URI += " \
        ${URL};branch=${BRANCH};protocol=https \
        file://${MACHINE}_defconfig \
        file://dts/sun8i-h3-nanopi.dtsi \
        file://dts/sun8i-h3-nanopi-neo.dts \
        file://dts/sun8i-h3-nanopi-neo-air.dts \
        file://debian \
        file://0001-Added-support-for-compiling-device-tree-overlays.patch \
        file://0002-can-mcp251x-Fixed-delay-after-hw-reset.patch \
        file://0003-spi-sun6i-Added-support-for-gpio-chipselect.patch \
        file://0004-spi-sun6i-Fixed-maximum-transfer-size-of-64bit.patch \
        file://0005-net-Added-device-tree-support-for-w5100-driver.patch \
        file://0006-can-mcp251x-Fixed-deadlock-for-free_irq-while-irq-wa.patch \
        "
SRC_URI_append_nanopi-neo-air = "file://firmware"

DTBO_SRC_DIR  = "arch/${TARGET_ARCH}/boot/dts/overlays"
DTBO_DEST_DIR = "boot/dts/overlays"

do_copy_device_tree() {
    cp  ${EXTRACTDIR}/dts/sun8i-h3-nanopi.dtsi \
        ${EXTRACTDIR}/dts/sun8i-h3-nanopi-neo.dts \
        ${EXTRACTDIR}/dts/sun8i-h3-nanopi-neo-air.dts \
        ${S}/arch/${TARGET_ARCH}/boot/dts
}
do_copy_defconfig[postfuncs] += "do_copy_device_tree"

# Overwrite the standart dtc with the overlay capable one.
debianize_build_prepend() {
    ${MAKE} scripts
    cp /opt/bin/overlay-dtc ${PPS}/scripts/dtc/dtc
}

# for now only install overlays.txt file
debianize_install_append() {
    echo "overlays=${DTBOS_LOAD}" | xargs > debian/${BPN}/boot/overlays.txt
}

# Install required firmware binary and nvram config file for
# ap6212 (BCM43430) wireless chipset
debianize_install_append_nanopi-neo-air() {
    install -m 644 -d debian/${BPN}/lib/firmware/brcm
    install -m 644 ${PP}/firmware/brcmfmac43430-sdio.bin.7.45.77.0.ucode1043.2054 debian/${BPN}/lib/firmware/brcm/brcmfmac43430-sdio.bin
    install -m 644 ${PP}/firmware/brcmfmac43430-sdio.txt debian/${BPN}/lib/firmware/brcm
}


BBCLASSEXTEND = "cross"
```

As this example shows you have to define such a kernel recipe, and customize it by defining own versions of debianize_* tasks for compiling and install different components.

**NOTE: The kernel class has to be inheritet after the debianize class. Otherwise defined tasks within the kernel class will be overwritten by the debianize class.**

The following example shows what is needed for setting up a simpler kernel recipe:
```
DESCRIPTION ?= "Mainline linux kernel support for the imx6."

DESCRIPTION_nitrogen6x = "Mainline linux kernel support for the nitrogen6x."

inherit debianize kernel
DEPENDS = "dtc-native"

URL = "git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"
BRANCH="master"
SRCREV = "eab260db417449f5c6500319c9d2f3fc33087051"

SRC_DIR = "git"
SRC_URI += " \
        ${URL};branch=${BRANCH};protocol=https \
        file://${MACHINE}_defconfig \
        file://firmware \
        file://debian \
        "

copy_firmware() {
    mkdir -p ${S}/firmware/
    cp -r ${EXTRACTDIR}/firmware/* ${S}/firmware/
}
do_build[prefuncs] += "copy_firmware"

BBCLASSEXTEND = "cross"
```

## Dependency management
The dependency management should as much as possible get managed by the package manager itself.
There are two kinds of main dependencies which should be distinguished:


### Dependencies to official debian packages
Other dependencies, mostly packages not generated by Isar itself, but installed from official debian repositories, where added to `DEB_DEPENDS` and
`DEB_RDEPENDS`.

The behavior is the same as for `DEPENDS` and `RDEPENDS`, but instead using dependencies to other recipes, dependencies to official debian binary packages where selected.
This also means, that specified elements will not be pushed onto the build chain of Isar!

When the recipe also provides crossbuild support, all items of `DEPENDS` and `RDEPENDS` will be suffixed with **-cross**. Keep that in mind, because
sometimes also some cross builded packages depend on a native (host arch) package.
To skipp those packages from beeing suffixed add the package name to `SKIP_APPEND_CROSS_SUFFIX`.
The same applies to native build packages, with `SKIP_APPEND_NATIVE_SUFFIX`.


### Dependencies to other recipes
In order to append other recipes to the dependency **and build chain** of Isar, these should added to the `DEPENDS` and `RDEPENDS` variables.
While the former one adds build-time dependencies the latter one will add run-time dependencies.
The control file template is substituted with the the associated values  of `DEPENDS` and `RDEPENDS`.

About the debian control file substitution, we can say that:

* Depends variable is substituted with RDEPENDS.
* Build-Depends is substituted with DEPENDS.

So Isar will substitute the related `control` file variables and the dpkg-buildpackage tool, used by Isar, will handle the dependency management. Isar will only run the basic tasks for compiling and installing the package to the local repository and dpkg-buildpackage, will install the dependend packages.

When a recipe provides multiple additional binary packages, the names of those packages should be appended to `PROVIDES`.
You can consider the `swupdate` and `u-boot` packages for example.
Uboot provides to binary packages: `uboot` and `libubootenv`. Swupdate in turn depends on the binary package `libubootenv`.
Uboot will provide the `libubootenv` package after adding it the provides variable.
Swupdate must add `libubootenv` to `DEPENDS`:

swupdate.bb:
```
DEPENDS += " mtd-utils-dev libubootenv "
```

uboot.bb:
```
PROVIDES_append = " libubootenv "
```


## Running chrooted tasks
Isar provides the functionality of running chrooted tasks within the created rootfs, buildchroot and cross-buildchroot filesystem, and defining these tasks as normal bitbake shell tasks.
For now only shell tasks are supported.
From the developers point of view defined chroot tasks where implemented and executed completely abstract from chrooted tasks, so the only thing to be done in order to run chrooted tasks is to write normal bitbake shell tasks and set some Variables, so the bitbake task execution engine knows how to handle these taks.

The chrooted environment is setup with the `schroot` tool, which in turn represents a wrapper for chroot.
Isar will setup the hosts schroot settings and configs at a very soon stage in the build process.

The following example shows how to setup simple chroot tasks:

```
do_mytask() {
  do somethin within the chroot target....
}

addtask do_mytask
do_mytask[chroot] = "1"
do_mytask[stamp-extra-info] = "${MACHINE}.chroot
do_mytask[id] = "${BUILDCHROOT_ID}"
```

So basically the following variables have to be set:
- `do_mytask[id]` - This will set the location of target chroot environment. One target (`ROOTFS_ID`) specifies the final rootfs location , which points to `ROOTFS_DIR`. And the other target (`BUILDCHROOT_ID`) specifies the buildchroot directory `BUILDCHROOT_DIR`. A third target(`CROSS_BUILDCHROOT_ID`) is setting the chroot destination to `CROSS_BUILDCHROOT_DIR`.
- `do_mytask[chroot]` - Enables the chroot if `1` is set.
- `do_mytask[stamp-extra-info]` - This function flag is not mandatory, but may be helpfull in case of detecting chrooted tasks at the recipes temp folder.


---

## Navigation through directories under tmp
`WORK IN PROGRESS`

---

## Troubleshooting
`WORK IN PROGRESS`

### Buildchroot/Cross-buildchroot errors

---
