# isar - Integration System for Automated Root filesystem generation

Isar is a set of scripts for building software packages and repeatable
generation of Debian-based root filesystems with customizations.

** Note: This repository was forked from https://github.com/ilbers/isar/ **

# Build

See doc/user_manual.md.

# Try

To test the QEMU image, run the following command:

        $ start_armhf_vm

The default root password is 'root'.

To test the RPi board, flash the image to an SD card using the insctructions from the official site,
section "WRITING AN IMAGE TO THE SD CARD":

    https://www.raspberrypi.org/documentation/installation/installing-images/README.md

# Support

This version of isar has no support yet, because for now it is under heavy development.


# Release Information

Built on:
* Linux Mint 18.1
* Debian 8.2

Tested on:
* No target board tests, yet.

**Note:** qemu-user-static has irregular problems while running multithreaded tasks.
These problems did not appear with qemu-user-static (=2.8).


# Credits
* Original
    * Developed by ilbers GmbH
    * Sponsored by Siemens AG
* Forked Version
    * Mixed Mode GmbH
    * Sponsored by Siemens AG