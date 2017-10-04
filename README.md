# ISAR (next generation)
Isar is a set of scripts for building software packages and repeatable
generation of Debian-based root filesystems with customizations.

``Note: This repository was forked from https://github.com/ilbers/isar and implements extended features.``

# Build
See doc/user_manual.md.

# Support
The project itself was basically introduced for extending the original ISAR buildsystem, but was first in a non-open-source state during development until
the customer gave the permissions for releasing this project on github.

As a main goal this repository was and is beeing developed in hope of getting a lot of features upstream to the main repository, after this release...
So let's hope the best and luckily the most or all changes will be merged into the mainline repository.

Therefore it would be a better way, depending on the mainling progress,  when contributing to the main repository.

Mailing lists:

* Using Isar: https://groups.google.com/d/forum/isar-users
  * Subscribe: isar-users+subscribe@googlegroups.com
  * Unsubscribe: isar-users+unsubscribe@googlegroups.com

* Collaboration: https://lists.debian.org/debian-embedded/
  * Subscribe: debian-embedded-request@lists.debian.org, Subject: subscribe
  * Unsubscribe: debian-embedded-request@lists.debian.org, Subject: unsubscribe


# Supported Hardware
* NanoPi Neo
* NanoPi Neo Air

# Release Information
Built on:

* Linux Mint 18.1
* Debian 8 (jessie)
* Debian 9 (stretch)

**Note:** qemu-user-static has irregular problems while running multithreaded tasks.
These problems did not appear with qemu-user-static (=2.8).


# Credits
* Original
    * Developed by ilbers GmbH
    * Sponsored by Siemens AG
* Forked Version
    * Mixed Mode GmbH
    * Sponsored by Siemens AG