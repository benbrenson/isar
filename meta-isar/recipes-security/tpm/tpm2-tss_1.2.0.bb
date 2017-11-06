DESCRIPTION = "Trusted Computing Group (TCG) TPM2 Software Stack (TSS)."
DESCRIPTION_DEV = "Include and pkgconfig files of the TPM2 Software Stack"
LICENSE = "bsd"

include tpm.inc

PROVIDES += "tpm2-tss-dev"

CONFIGURE = "./configure --prefix=${PPS}/debian/tmp${prefix}"

URL = "git://github.com/01org/tpm2-tss.git"
SRCREV = "24f555ce72183f989de900e86e5e8af687c39f78"
BRANCH = "master"
