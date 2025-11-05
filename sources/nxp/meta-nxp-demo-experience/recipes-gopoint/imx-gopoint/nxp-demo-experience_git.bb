SUMMARY = "GoPoint for i.MX Application Processors"
DESCRIPTION = "Launcher for GoPoint for i.MX Application Processors"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=2d059bbe3d7ade0650b00b547c1845e3"

NXP_DEMO_SRC ?= "git://github.com/nxp-imx-support/nxp-demo-experience.git;protocol=https"
NXP_DEMO_BRANCH ?= "lf-6.6.52_2.2.0"
NXP_DEMO_SRCREV ?= "52e5d30673f75ab5a53f6541f2845894b8fc0b05"

PV = "${NXP_DEMO_BRANCH}+git${NXP_DEMO_SRCREV}"

SRC_URI = "${NXP_DEMO_SRC};branch=${NXP_DEMO_BRANCH};name=nxp-demo-experience"
SRCREV = "${NXP_DEMO_SRCREV}"

S = "${WORKDIR}/git"

inherit qt6-qmake

DEPENDS += " \
    qtbase \
    qtdeclarative \
    ncurses \
"

RDEPENDS:${PN}+= " qtbase \
    qtdeclarative \
    ncurses \
    qt5compat \
"

do_install() {
    install -d -m 755 ${D}${bindir}
    install ${B}/demoexperience ${D}${bindir}
    ln -sfr ${D}${bindir}/demoexperience ${D}${bindir}/gopoint

    install -d -m 755 ${D}${GPNT_APPS_FOLDER}
}

FILES:${PN} += "${bindir}/demoexperience ${bindir}/gopoint ${GPNT_APPS_FOLDER}"
