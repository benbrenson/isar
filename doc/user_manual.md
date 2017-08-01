# ISAR User Manual

## Contents

 - [Introduction](https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar/blob/siemens/doc/user_manual.md#introduction)
 - [Getting Started](https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar/blob/siemens/doc/user_manual.md#getting-started)
 - [Terms and Definitions](https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar/blob/siemens/doc/user_manual.md#terms-and-definitions)
 - [How Isar Works](https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar/blob/siemens/doc/user_manual.md#how-isar-works)
 - [General Isar Configuration](https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar/blob/siemens/doc/user_manual.md#general-isar-configuration)
 - [Isar Distro Configuration](https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar/blob/siemens/doc/user_manual.md#isar-distro-configuration)
 - [Custom Package Compilation](https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar/blob/siemens/doc/user_manual.md#custom-package-compilation-1)
 - [Image Type Selection](https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar/blob/siemens/doc/user_manual.md#image-type-selection)
 - [Add a New Distro](https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar/blob/siemens/doc/user_manual.md#add-a-new-distro)
 - [Add a New Machine](https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar/blob/siemens/doc/user_manual.md#add-a-new-machine)
 - [Add a New Image](https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar/blob/siemens/doc/user_manual.md#add-a-new-image)
 - [Add a New Image Type](https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar/blob/siemens/doc/user_manual.md#add-a-new-image-type)
 - [Add a Custom Application (debian compatible)](https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar/blob/siemens/doc/user_manual.md#add-a-custom-application-(debian-compatible))
 - [Add a Custom Application (not debian compatible)](https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar/blob/master/doc/user_manual.md#add-a-custom-application-(not-debian-compatible))
 - [Running chrooted tasks natively](https://github.com/ilbers/isar/blob/master/doc/user_manual.md#running-chrooted-tasks-natively)


## Introduction

Isar is a set of scripts for building software packages and repeatable generation of Debian-based root filesystems with customizations.

Isar provides:
 - Fast target image generation: About 10 minutes to get base system image for one machine.
 - Use any apt package provider, including open-source communities like `Debian`, `Raspbian`, etc. and proprietary ones created manually.
 - Native compilation: Packages are compiled in a `chroot` environment using the same toolchain and libraries that will be installed to the target filesystem.
 - Product templates that can be quickly re-used for real projects.

---

## Getting Started
The steps below describe how to build the images provided by default.

### Install Host Tools

Install the following packages:
```
dosfstools
git
mtools
multistrap
parted
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
```
Notes:
* BitBake requires Python 3.4+.
* The python3 package is required for the correct `alternatives` setting.
* qemu-user-static should be higher or equal than 2.8, because this version supports propper threading support.
  * Otherwise the build will fail arbitrarily at rootfs creation time with qemu `core dumped` errors.

### Setup Sudo

Isar requires `sudo` rights without password to work with `chroot` and `multistrap`. To add them, use the following steps:
```
 # visudo
```
In the editor, allow the current user to run sudo without a password, e.g.:
```
 <user>  ALL=NOPASSWD: ALL
```
Replace `<user>` with your user name. Use the tab character between the user name and parameters.

### Check out Isar and required meta-layers
This section describes how to fetch and prepare the build environment by your own.

```
BUILDDIR="build-relase"
mkdir ebs-isar
cd ebs-isar

mkdir sources
mkdir $BUILDDIR

git clone https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_build-config.git $BUILDDIR
git clone https://git.pixel-group.de/siemens-ct/Siemens_CT_REE_isar.git sources/isar
git clone https://git.pixel-group.de/siemens-ct/Siemens_CT_REE-meta-siemens.git sources/meta-siemens
git clone https://@git.pixel-group.de/siemens-ct/Siemens_CT_REE-meta-sunxi.git sources/meta-sunxi
```

**Note: Since some repositories are reachable via https, you need to provide the required credentials via git-credentials:**
```
git config --global credential.helper store
echo "https://<username>:<password>@git.pixel-group.de.de" ~/.git-credentials
```

### Initialize the Build Directory
The main parts of setting up the build directory where already done at the last step.
Now the following have to be done:
```
$ BUILDDIR="build-relase"
$ cd ebs-isar
$ cp $BUILDDIR/setup-environment .
$ source setup-environment $BUILDDIR
```

### Build Images

The following command will produce `isar-image-base` image:
```
$ bitbake multiconfig:nanopi:isar-image-base
```
**Note:** For now only nanopi images are possible to build.

Created images are:
```
NONE
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

This filesystem is generated similarly to the `buildchroot` one using the `apt` binaries repository. Please refer to distro configuration chapter for more information.

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

This file contains the list of meta layers, where `bitbake` will search for recipes, classes and configuration files. By default, Isar includes the following layers:
 - `meta` - Core Isar layer which contains basic functionality.
 - `meta-isar` - Product template layer. It demonstrates Isar's features. Also this layer can be used to create your projects.

### local.conf

This file contains variables that will be exported to `bitbake` environment and will be processed in recipes. The default Isar configuration uses the following variables:

 - `BBMULTICONFIG` - The list of the machines to include the respective configuration files. If this option is omitted, user has to manually define the pair `MACHINE`/`DISTRO` for specific target.
 - `IMAGE_INSTALL` - The list of custom packages to build and install to target image, please refer to relative chapter for more information.
 - `BB_NUMBER_THREADS` - The number of `bitbake` jobs that can be run in parallel. Please set this option according your host CPU cores number.

### bitbake.conf

This file contains the global definitions for all bitbake recipes and classes. This file also includes the `conf/distro/${DISTRO}.conf` and `conf/machine/${MACHINE}.conf` files located in respective layer directories.


---

## Isar Distro Configuration

In Isar, each machine can use its specific Linux distro to generate `buildchroot` and target filesystem. By default, Isar provides configuration files for the following distros:
 - debian-wheezy
 - raspbian-stable

User can select appropriate distro for specific machine by setting the following variable in machine configuration file:
```
DISTRO = "distro-name"
```

---

## Custom Package Compilation

Isar provides possibility to compile and install custom packages. The current version supports building `deb` packages using `dpkg-buildpackage`, so the sources should contain the `debian` directory with necessary meta information. It is also possible to provide a debian directory with a `control` and `rules` file, at the recipes folder.

To add new package to image, it needs the following:
 - Create package recipe and put it in your `isar` layer.
 - Append `IMAGE_INSTALL` variable by this recipe name. If this package should be included for all the machines, put `IMAGE_INSTALL` to `local.conf` file. If you want to include this package for specific machine, put it to your distro configuration file.

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
 - `DISTRO_CONFIG_SCRIPT` - Target filesystem finalization script. This script is called after `multistrap` has unpacked the base system packages. It is designed to finalize filesystem, for example to add `fstab` according to machine hardware configuration. The script should be placed to `files` folder in image recipe folder.
 - `IMAGE_PREINSTALL` - The list of distro-specific packages, that has to be included to image.

Below is an example for Raspbian stable:
```
DISTRO_SUITE = "stable"
DISTRO_ARCH = "armhf"
DISTRO_COMPONENTS = "main contrib non-free firmware"
DISTRO_APT_SOURCE = "http://archive.raspbian.org/raspbian"
DISTRO_CONFIG_SCRIPT = "raspbian-configscript.sh"
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
 - The distro configuration file should only contain distribution specific definitions, which in turn means only including software packages for the rootfs.
 - Do not include board dependent things within this file, except ${DISTRO_ARCH}.

---

## Add a New Machine

Every machine is described in its configuration file. The file defines the following variables:
 - `KIMAGE_TYPE` - The name of kernel binary that it installed to `/boot` folder in target filesystem. This variable is used by isar for determing which
 image type has to be compiled by the kernel.
 - `INITRD_IMAGE` - The name of `ramdisk` binary. The meaning of this variable is similar to `KERNEL_IMAGE`. This variable is optional.
 - `MACHINE_SERIAL` - The name of serial device that will be used for console output.
 - `IMAGE_TYPE` - The type of images to be generated for this machine.
 - `DTBS` - The primary device tree file. Isar will install this device tree to the location specified with ${DTB_INSTALL_DIR}.
 - `DTBOS` - Device tree overlay files. The kernel has to be capable of compiling device tree overlays.
 - `BOOT_IMG` - The name of the uboot image. Isar will also build a complete debian package for uboot.
 - `UIMAGE_LOADADDR` - The uImage loadaddress. Only required if ${KIMAGE_TYPE} is uImage.
 - `TARGET_ARCH` - The target architecture required by different buildsystems (e.g. Kconfig). Please do not set a debian specific architecture type here.
Below is an example of machine configuration file for `NanoPi-Neo` board:
```
KIMAGE_TYPE="uImage"
KERNEL_CMDLINE="bootargs=console=ttyS0,115200 console=tty1 root=/dev/mmcblk0p2 rw rootwait panic=10"

UIMAGE_LOADADDR="0x40008000"
DTBS="sun8i-h3-nanopi-neo.dtb"
DTBOS="sun8i-h3-i2c0.dtbo \
          sun8i-h3-i2c1.dtbo \
          sun8i-h3-i2c2.dtbo \
          sun8i-h3-spi-mcp2515.dtbo \
          sun8i-h3-sc16is760.dtbo \
         "
BOOT_IMG = "u-boot-sunxi-with-spl.bin"
MACHINE_SERIAL = "ttyS0"
IMAGE_TYPE = "rpi-sdimg"
TARGET_ARCH="arm"
```

To add new machine user should perform the following steps:
 - Create the `machine` directory in your layer:

    ```
    $ mkdir meta-user/conf/machine
    ```

 - Create `.conf` file in machine folder with the name of your machine.
 - Define in this file variables, that described above in this chapter.
 - The machine configuration file should only define machine specific variables, which in turn means describing hardware dependent properties like kernel, bootloader, firmware packages.

---

## Add a New Image

Image in Isar contains the following artifacts:
 - Image recipe - Describes set of rules how to generate target image.
 - `Multistrap` configuration file - Contains information about distro, suite, `apt` source etc.
 - `Multistrap` setup script - Performs pre-install filesystem configuration.
 - `Multistrap` config script - Performs post-install filesystem configuration.

In image recipe, the following variable defines the list of packages that will be included to target image: `IMAGE_PREINSTALL`. These packages will be taken from `apt` source.

The user may use `met-isar/recipes-core-images` as a template for new image recipes creation.

---

## Add a new Image
### General Information
The image recipe in Isar creates a folder with target root filesystem. The default its location is:
```
tmp/rootfs/${MACHINE}
```
Isar uses the openembedded tool called **wic** for creating bootable rootfs images.
For describing the partition layout for images, wic in turn uses so called **kickstart** files.

There are two things to be done in order to create new image types:
1. Create a new kickstart file
2. Set the **${IMAGE_PART_DESC}** variable to point to the the new created kickstart file.


### Create Custom Image
As already mentioned, Isar uses `bitbake`to accomplish the work. The whole build process is a sequence of tasks. This sequence is generated using task dependencies, so the next task in chain requires completion of previous ones.
The last task of image recipe is `do_post_rootfs`, so if you want to do customize the rootfs at the very last moment of creation you can overwrite this task.
**Note: The `do_post_rootfs` task will per default run in a chrooted environment, so only access to directories within tmp/rootfs/${MACHINE} will be possible.
For more information about chrooted tasks please refer to `Running chrooted tasks natively` section.

new_image.bb:
```
include isar-image-base
IMAGE_PART_DESC = "${THISDIR}/files/new_image.wks"

# Extra space appended to rootfs partitions
ROOTFS_EXTRA="100"

# Additional packages to install (from debian repositories)
IMAGE_PREINSTALL += " openssh-server "

# Additional packages to install (from other recipes)
IMAGE_INSTALL += " example_recipe "
```

new_image.wks:
```
# Example kickstart file for creating a sd-card image with two redundant rootfs partitions.

# Save the bootloader into free space after the MBR and before the start of the first partition.
bootloader --source bootstream

# Bootpartition
part /boot --source bootimg-partition --ondisk mmcblk --fstype=vfat --label boot --active --align 2048

# First rootfs partition
part / --source rootfs --rootfs-dir=rootfs1 --ondisk mmcblk --fstype=ext4 --label root --align 2048

# Second rootfs partition
part /rescue --source rootfs --rootfs-dir=rootfs2 --ondisk mmcblk --fstype=ext4 --label root --align 2048
```

**Note: No flash filesystems are supported (e.g. ubifs or jffs), yet.**

---

## Add a Custom Application (debian compatible)
The isar buildsystem is capable of compiling software (cross compiling **and** qemu emulated native compiling) and creating debian compatible packages.
But what is a debian compatible package?
A debian compatible package is a piece of software, which already contains the required ```debian folder``` with all debian specific contents
(rules, control file etc.)
The main steps for creating, already debian compatible, custom applications is as follows:

* Download the software
* Compile the software (cross or native) and create a debian package
* Install the debian package into the debian deploy folder

Before creating new recipe it's highly recommended to take a look into the BitBake user manual mentioned in Terms and Definitions section.

Current Isar version supports building packages in Debian format only. The package itself must contain the `debian` directory with the necessary metadata.If the package is not debian compatible, it has to be debianized first. Please refer to Add a Custom Application (not debian compatible) section for more information.

### Cross compilation
A typical Isar recipe for debian compatible software looks like this:

```
DESCRIPTION = "Sample application for ISAR"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

SRC_URI = "git://github.com/ilbers/hello.git"
SRCREV = "ad7065ecc4840cc436bfcdac427386dbba4ea719"

SRC_DIR = "git"

inherit dpkg-cross
```

### Native compilation
A typical Isar recipe for debian compatible software looks like this:

```
DESCRIPTION = "Sample application for ISAR"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

SRC_URI = "git://github.com/ilbers/hello.git"
SRCREV = "ad7065ecc4840cc436bfcdac427386dbba4ea719"

SRC_DIR = "git"

inherit dpkg
```

The following variables are used in the recipes:
 - `DESCRIPTION` - Textual description of the package.
 - `LICENSE` - Application license file.
 - `LIC_FILES_CHKSUM` - Reference to the license file with its checksum. Isar recommends to store license files for your applications into your layer folder `meta-user/licenses/`. Then you may reference it in recipe using the following path:

    ```
    LIC_FILES_CHKSUM = file://${LAYERDIR_isar}/licenses/...
    ```
This approach prevents duplication of the license files in different packages.
 - `PV` - Package version.
 - `SRC_URI` - The link where to fetch application source. Please check the BitBake user manual for supported download formats.
 - `SRC_DIR` - The directory name where application sources will be unpacked. For `git` repositories, it should be set to `git`. Please check the BitBake user manual for supported download formats.
 - `SRC_REV` - Source code revision to fetch. Please check the BitBake user manual for supported download formats.

The last line in the example above adds recipe to the Isar work chain.

## Add a Custom Application (not debian compatible)
### Native compilation
### Cross compilation
## Running chrooted tasks
Isar provides the functionality of running chrooted tasks within the created rootfs or buildchroot filesystem, and defining these tasks as normal bitbake
shell tasks. For now only shell tasks where supported.
From the developers point of view defined chroot tasks where implemented and executed completely abstracted from chrooted tasks, so the only thing to be done in order
to run chrooted tasks is to write normal bitbake shell tasks and set some Variables, so the bitbake task execution engine knows how to handle these taks.

The chrooted environment is setup with the `schroot` tool, which in turn represents a wrapper for chroot.
Isar will setup the hosts schroot settings and configs at a very soon stage in the build process.

The following example shows how to setup simple chroot tasks:

```
PP ="/home/builder"

do_mytask() {
  do somethin within the chroot target....
}

addtask do_mytask
do_mytask[chroot] = "1"
do_mytask[stamp-extra-info] = "${MACHINE}.chroot
do_mytask[id] = "${BUILDCHROOT_ID}"
```

So basically the following variables have to be set:
- `do_mytask[id]` - This will set the location of target chroot environment. One target (`ROOTFS_ID`) specifies the final rootfs location , which points to `ROOTFS_DIR`. And the other target (`BUILDCHROOT_ID`) specifies the buildchroot directory `BUILDCHROOT_DIR`.
- `PP` - The directory to switch within chroot. This has to be a existend directory.
- `do_mytask[chroot]` - Enables the chroot if `1` is set.
- `do_mytask[stamp-extra-info]` - This function flag is not mandatory, but may be helpfull in case of detecting chrooted tasks at the recipes temp folder.
