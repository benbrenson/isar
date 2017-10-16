DESCRIPTION = "Python mqtt client library."
LICENSE = "gpl"

inherit dpkg debianize-python

URL = "https://pypi.python.org/packages/33/7f/3ce1ffebaa0343d509aac003800b305d821e89dac3c11666f92e12feca14/paho-mqtt-1.3.0.tar.gz"

PYTHON_VERSION = "3"

SRC_DIR = "paho-mqtt-${PV}"
SRC_URI[sha256sum] = "2c9ef5494cfc1e41a9fff6544c5a2cd59ea5d401d9119a06ecf7fad6a2ffeb93"
SRC_URI[md5sum] = "b9338236e2836e8579ef140956189cc4"

SRC_URI += "${URL} \
            file://debian \
           "

SECTION = "python"
PRIORITY = "optional"
