
SRCBRANCH = "lf-6.6.52_2.2.0"
SRCREV = "44dd492a745cd8b8313fb6c7c03fb45a36d70e8a"

PV = "2023.03+git${SRCPV}"

IMX_JAILHOUSE_SRC ?= "git://github.com/nxp-imx/imx-jailhouse.git;protocol=https"
SRC_URI = "${IMX_JAILHOUSE_SRC};branch=${SRCBRANCH}"

RDEPENDS:${PN} += " \
    pyjailhouse \
"
COMPATIBLE_MACHINE = "(mx8m-nxp-bsp|mx8ulp-nxp-bsp|mx9-nxp-bsp)"
