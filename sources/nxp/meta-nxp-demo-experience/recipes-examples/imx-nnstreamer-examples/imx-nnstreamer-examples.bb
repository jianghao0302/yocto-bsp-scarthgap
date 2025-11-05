SUMARY = "NNStreamer Examples"
DESCRIPTION = "Recipe for i.MX NNStreamer Examples"
SECTION = "Machine Learning"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3d5621953a6b13048ccb5e891b99e00e"

IMX_NNSTREANER_DIR = "${GPNT_APPS_FOLDER}/scripts/machine_learning/nnstreamer"

NXP_NNSTREAMER_EXAMPLES_SRC ?= "git://github.com/nxp-imx/nxp-nnstreamer-examples.git;protocol=https"
SRCBRANCH = "main"
SRCREV = "5d9a7a674e5269708f657e5f3bbec206fb512349"

SRC_URI = "${NXP_NNSTREAMER_EXAMPLES_SRC};branch=${SRCBRANCH}"
S = "${WORKDIR}/git"

DEPENDS = "\
        tensorflow-lite \
        glib-2.0 \
        gstreamer1.0 \
        nnstreamer \
"

RDEPENDS:${PN} = "\
        tensorflow-lite \
        glib-2.0 \
        gstreamer1.0 \
        nnstreamer \
        bash \
"

inherit pkgconfig cmake

EXTRA_OECMAKE = "-DCMAKE_SYSROOT=${PKG_CONFIG_SYSROOT_DIR}"

do_install() {
    install -d ${D}${IMX_NNSTREANER_DIR}

    cp ${WORKDIR}/git/LICENSE ${D}${IMX_NNSTREANER_DIR}
    cp ${WORKDIR}/git/SCR*.txt ${D}${IMX_NNSTREANER_DIR}

    install -d ${D}${IMX_NNSTREANER_DIR}/classification
    install -m 0755 ${WORKDIR}/build/classification/* ${D}${IMX_NNSTREANER_DIR}/classification

    install -d ${D}${IMX_NNSTREANER_DIR}/detection
    install -m 0755 ${WORKDIR}/build/detection/* ${D}${IMX_NNSTREANER_DIR}/detection

    install -d ${D}${IMX_NNSTREANER_DIR}/pose
    install -m 0755 ${WORKDIR}/build/pose/* ${D}${IMX_NNSTREANER_DIR}/pose
    
}

FILES:${PN} += "${IMX_NNSTREANER_DIR}/*"

COMPATIBLE_MACHINE = "(mx8-nxp-bsp|mx9-nxp-bsp)"
