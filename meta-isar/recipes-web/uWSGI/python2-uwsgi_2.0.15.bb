DESCRIPTION = "Web Server Gateway Interface."
LICENSE = "gpl2"

inherit dpkg debianize-python

DEB_DEPENDS += " python-dev"

URL = "https://pypi.python.org/packages/bb/0a/45e5aa80dc135889594bb371c082d20fb7ee7303b174874c996888cc8511/uwsgi-2.0.15.tar.gz"

SRC_DIR = "uwsgi-${PV}"
SRC_URI[sha256sum] = "572ef9696b97595b4f44f6198fe8c06e6f4e6351d930d22e5330b071391272ff"
SRC_URI[md5sum] = "fc50bd9e83b7602fa474b032167010a7"

SRC_URI += "${URL} \
            file://debian \
           "

SECTION = "python"
PRIORITY = "optional"
