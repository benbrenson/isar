DESCRIPTION = "TPM (Trusted Platform Module) 2 tools based on tpm2-tss"
LICENSE = "bsd"

include tpm.inc

DEB_DEPENDS += "libssl-dev \
		libcurl4-gnutls-dev \
		"

DEPENDS += "	tpm2-tss \
		tpm2-tss-dev \
		"

CONFIGURE = "./configure --prefix=${PPS}/debian/${PN}${prefix}"

URL = "git://github.com/01org/tpm2-tools.git"
SRCREV = "fa9fe7a749521600e990f88e95e4c79e16b7bf48"
BRANCH = "master"
