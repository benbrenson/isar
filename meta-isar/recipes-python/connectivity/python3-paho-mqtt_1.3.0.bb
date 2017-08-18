DESCRIPTION = "Python mqtt client library."
LICENSE = "gpl"

inherit dpkg debianize-python

URL = "https://pypi.python.org/packages/33/7f/3ce1ffebaa0343d509aac003800b305d821e89dac3c11666f92e12feca14/paho-mqtt-1.3.0.tar.gz"

SRC_DIR = "paho-mqtt-${PV}"
SRC_URI += "${URL} \
            file://debian \
           "

SECTION = "python"
PRIORITY = "optional"
