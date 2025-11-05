# Copyright (C) 2012-2016 O.S. Systems Software LTDA.
# Copyright (C) 2013-2016 Freescale Semiconductor
# Copyright 2017-2022 NXP

FILESEXTRAPATHS:prepend := "${THISDIR}/imx-test:"

DEPENDS:append:mx8ulp-nxp-bsp = " imx-lib"
DEPENDS:append:mx93-nxp-bsp = " imx-lib"

SRC_URI = "${IMXTEST_SRC};branch=${SRCBRANCH} \
           file://memtool_profile"

IMXTEST_SRC ?= "git://github.com/nxp-imx/imx-test.git;protocol=https"
SRCBRANCH = "lf-6.6.52_2.2.0"
SRCREV = "26925d3b738dee65d075ac05a54fbecd4d2c0373" 

PLATFORM:mx8ulp-nxp-bsp = "IMX8ULP"
PLATFORM:mx91-nxp-bsp = "IMX8"
PLATFORM:mx93-nxp-bsp = "IMX8ULP"
PLATFORM:mx95-nxp-bsp = "IMX8"
