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
 - **No root privileges required anymore!**
 - Cross compilation of resource intensive source packages (e.g. QT, linux-kernel etc.)
 - Debianizing of non Debian compatible source code repositories.
 - Defining bitbake shell tasks, which are running in chrooted environments. This abstracts a lot of complexity related to chrooted tasks and will
 add support of layering those defined tasks.
 - Build images with docker.
 - Linux Firmware update with swupdate (meta-swupdate required).


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
qemu-user
proot
mtd-utils
util-linux
dh-make
u-boot-tools
bc
device-tree-compiler
quilt
```

When running docker based builds, the following packages should also be installed:
```
docker-compose
docker
```

**Notes:**
* BitBake requires Python 3.4+.
* The python3 package is required for the correct `alternatives` setting.
* qemu-user-static should be higher or equal than 2.8, because this version supports propper threading support.
  * Otherwise the build will fail arbitrarily at rootfs creation time with qemu `core dumped` errors.

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
    DEB_HOST_ARCH="amd64"
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
 - `DEB_HOST_ARCH` - The build host architecture (later this should be autodetected).
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
Every machine is described in its configuration file. The file defines the following variables:

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


Below is an example of machine configuration file for `NanoPi-Neo` board:
```
FIX_KVERSION="4.13.0-rc5"
KIMAGE_TYPE="uImage"
KERNEL_CMDLINE="console=${MACHINE_SERIAL},115200 console=tty1 rw rootwait panic=10"

UIMAGE_LOADADDR="0x40008000"

BOOT_IMG = "u-boot-sunxi-with-spl.bin"

MACHINE_SERIAL = "ttyS0"

IMAGE_FSTYPES = "ext4 sdcard-redundant"

# Set further target architecture specifics
TARGET_ARCH="arm"
TARGET_PREFIX="arm-linux-gnueabihf"

# Using for interface compatibility
DEB_ARCH="${DISTRO_ARCH}"


# Boot device required by u-boot
BOOT_DEVICE_NAME = "mmc"
BOOT_DEVICE_NUM="0"

BOOTP_PRIM_NUM = "1"
BOOTP_SEC_NUM = "2"

ROOTDEV_PRIM = "/dev/mmcblk0p2"
ROOTDEV_SEC  = "/dev/mmcblk0p3"

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

In image recipe, the following variable defines the list of packages that will be included to target image: `IMAGE_PREINSTALL`. These packages will be taken from `apt` source.

The user may use `meta-isar/recipes-core` as a template for new image recipes creation.


### General Information
The image recipe in Isar creates a folder with the target root filesystem. The default location is:
```
tmp/rootfs/${MACHINE}
```
Isar uses the openembedded tool called **wic** for creating bootable rootfs images.
For describing the partition layout for images, wic in turn uses so called **kickstart** files.

There are two things to be done in order to create new image types:
1. Create a new kickstart file
2. Add the image type to `SUPPORTED_FSTYPES` if it is not present there, yet.


Currently supported filesystem types are:

* sdcard (simple sd card image with two partitions: boot, rootfs)
* sdcard-redundant(same as sdcard but containing two equal rootfs partitions)
* ext4(ext4 partition image)



### Create Custom Image
new_image.bb:
```
inherit debian-image
SRC_URI += "file://new_image.wks \
           "

# Additional packages to install (from debian repositories)
IMAGE_PREINSTALL += " openssh-server "

# Additional packages to install (from other recipes)
IMAGE_INSTALL += " linux-image-cross u-boot-cross "

ROOTFS_IMAGE_SIZE = "4000M"
```
- `ROOTFS_IMAGE_SIZE` - Size of the rootfs partition. Multipliers k, M ang G can be used.


new_image.wks:
```
# Example kickstart file for creating a sd-card image with two redundant rootfs partitions.
# Save the bootloader into free space after the MBR and before the start of the first partition.
bootloader --source bootstream

# Bootpartition
part /boot --source bootimg-partition --ondisk mmcblk --fstype=vfat --label boot --active --align 2048

# First rootfs partition
part / --source rootfs --rootfs-dir=rootfs1 --ondisk mmcblk --fstype=ext4 --label root --align 2048 ##ROOTFS_SIZE_OPTION##

# Second rootfs partition
part /rescue --source rootfs --rootfs-dir=rootfs2 --ondisk mmcblk --fstype=ext4 --label root --align 2048 ##ROOTFS_SIZE_OPTION##
```

 - `##ROOTFS_SIZE_OPTION##` - This variable is getting substituted with `ROOTFS_IMAGE_SIZE`.


**Note: No flash filesystems are supported (e.g. ubifs or jffs), yet.**


### Last steps (rootfs customizations at the end)
As already mentioned, Isar uses `bitbake`to accomplish the work. The whole build process is a sequence of tasks. This sequence is generated using task dependencies, so the next task in chain requires completion of previous ones.
A list of tasks for the image recipe is contained in `POST_ROOTFS_TASKS`, so if you want to do customize the rootfs at the very last moment of creation, you can add all required tasks to this variable.
```
do_foo(){
    do something
}

POST_ROOTFS_TASKS += "do_foo;"
```

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

**Note: The current version of Isar requires using tabulator as identation when defining makefile tasks in recipes.**


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
`WORK IN PROGRESS`


## Dependency management
The dependency management should as much as possible get managed by the package manager itself.
There are two kinds of main dependencies which should be distinguished:

### Dependencies to other recipes
In order to append other recipes to the dependency **and build chain** of Isar, these should added to the `DEPENDS` and `RDEPENDS` variables.
While the former one adds build-time dependencies the latter one will add run-time dependencies.
The control file template is substituted with the the associated values  of `DEPENDS` and `RDEPENDS`.

About the debian control file substitution, we can say that:

* Depends variable is substituted with RDEPENDS.
* Build-Depends is substituted with DEPENDS.

This behavior is specified by debian.


### Dependencies to official debian packages
Other dependencies, mostly packages not generated by Isar itself, but installed from official debian repositories, where added to `DEB_DEPENDS` and
`DEB_RDEPENDS`.

The behavior is the same as for `DEPENDS` and `RDEPENDS`, but instead using dependencies to other recipes, dependencies to official debian binary packages
where selected.
This also means, that specified elements will not be pushed onto the build chain of Isar!

**Note:** A little bug is still present, when setting dependencies to a Isar generated binary package (multiple binary packages can be build out of one debian source package), whose name differs from the recipe name.
A workaround would be to add the recipe itself to `DEPENDS` or `RDEPENDS` and also add the binary package name to `DEB_DEPENDS` or `DEB_RDEPENDS`.
This will ensure putting the the recipe to the work chain and also install the dependency into the local debian repository.
A example is the `libubootenv` package, which is a binary package build out of the u-boot recipe (u-boot source package).
While `DEPENDS` has to contain u-boot (or u-boot-cross), `DEP_DEPENDS` contains the libubootenv dependency.


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
do_mytask[chrootdir] = "${BUILDCHROOT_DIR}"
```

So basically the following variables have to be set:
- `do_mytask[chrootdir]` - This will set the location of target chroot environment.
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
