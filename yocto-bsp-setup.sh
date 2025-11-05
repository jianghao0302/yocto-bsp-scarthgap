#!/usr/bin/env bash
# File: /home/work/nxp/yocto-bsp-setup.sh
# 描述: Yocto BSP 初始化与构建脚本模板（基础格式已填充）
# 使用: ./yocto-bsp-setup.sh [options]
# 说明: 这是一个通用模板，请根据实际 BSP/board/layers 修改变量与函数内的占位内容。

# set -euo pipefail
# IFS=$'\n\t'

PROG_NAME="yocto-bsp-setup.sh"
# Determine script directory robustly so this script works when executed
# or when sourced. When sourced, $1 may be the first positional parameter
# passed to the current shell (for example "-m") which must NOT be used
# to compute the script directory. Use BASH_SOURCE[0] when available,
# fall back to $0, and finally to '.' as a safe default.
if [ -n "${BASH_SOURCE:-}" ]; then
    SCRIPT_SOURCE="${BASH_SOURCE[0]}"
else
    SCRIPT_SOURCE="${0:-.}"
fi
TOP_DIR=$(cd "$(dirname "${SCRIPT_SOURCE:-.}")" && pwd)

# Any Ubuntu machine type
UBUNTU_MACHINE=".+ubuntu"

# Supported yocto version
YOCTO_VERSION="scarthgap"

# Default distro if not provided
DEFAULT_DISTRO="poky"

# Error codes
EINVAL=128

ROOT_DIR=${TOP_DIR}
SOURCES_DIR=${ROOT_DIR}/sources
YOCTO_LAYER_ROOT_DIR=${SOURCES_DIR}/yocto
COMMON_LAYER_ROOT_DIR=${SOURCES_DIR}/common
FSL_LAYER_ROOT_DIR=${SOURCES_DIR}/freescale
NXP_LAYERROOT_DIR=${SOURCES_DIR}/nxp
OE_ROOT_DIR=${YOCTO_LAYER_ROOT_DIR}/poky
if [ -e ${YOCTO_LAYER_ROOT_DIR}/oe-core ]; then
    OE_ROOT_DIR=${YOCTO_LAYER_ROOT_DIR}/oe-core
fi
META_ALPHA_ROOT_DIR=${SOURCES_DIR}/meta-alpha
FSL_ROOT_DIR=${FSL_LAYER_ROOT_DIR}/meta-freescale
# Do not reference ${MACHINE} yet (it may be unset). Set PROJECT_DIR to a
# safe default; it will be updated later after parsing arguments.
PROJECT_DIR=${ROOT_DIR}/build

# Check if current user is root
if [ "$(whoami)" = "root" ]; then
    echo "ERROR: Do not use the BSP as root. Exiting..."
    unset ROOT_DIR PROG_NAME
    return
fi


prompt_message () {
local i=''
echo "Welcome to Linux BSP 

The Yocto Project has extensive documentation about OE including a
reference manual which can be found at:
    http://yoctoproject.org/documentation

For more information about OpenEmbedded see their website:
    http://www.openembedded.org/

You can now run 'bitbake <target>'
"
    echo "Targets specific to ${MACHINE}:"
    for layer in $(echo $LAYER_LIST | xargs); do
        fsl_recipes=$(find $layer -path "*recipes-*/images/fsl*.bb" -or -path "images/fsl*.bb" 2> /dev/null)
        if [ -n "$fsl_recipes" ]
        then
            for i in $(echo $fsl_recipes | xargs);do
                i=$(basename $i);
                i=$(echo $i | sed -e 's,^\(.*\)\.bb,\1,' 2> /dev/null)
                echo "    $i";
            done
        fi
    done

    echo "To return to this build environment later please run:"
    echo "    . $PROJECT_DIR/SOURCE_THIS"
}

clean_up()
{
   unset PROG_NAME ROOT_DIR OE_ROOT_DIR FSL_ROOT_DIR PROJECT_DIR \
         EULA EULA_FILE LAYER_LIST MACHINE FSLDISTRO \
         OLD_OPTIND CPUS JOBS THREADS DOWNLOADS CACHES DISTRO \
         setup_flag setup_h setup_j setup_t setup_l setup_builddir \
         setup_download setup_sstate setup_error layer append_layer \
         extra_layers alb_user_extra_layers distro_override \
         MACHINE_LAYER MACHINE_EXCLUSION ARM_MACHINE

   unset -f usage prompt_message
}

usage() {
    echo "Usage: . $PROG_NAME -m <machine>"
    # ls $FSLROOTDIR/conf/machine/*.conf > /dev/null 2>&1

    # if [ $? -eq 0 ]; then
    #     echo -n -e "\n    Supported machines: "
    #     for layer in $(eval echo $LAYER_LIST); do
    #         if [ -d ${layer}/conf/machine ]; then
    #             echo -n -e "`ls ${layer}/conf/machine | grep "\.conf" \
    #                | egrep -v "^${MACHINE_EXCLUSION}" | sed s/\.conf//g | xargs echo` "
    #         fi
    #     done
    #     echo ""
    # else
    #     echo "    ERROR: no available machine conf file is found. "
    # fi

    echo "    Optional parameters:
    * [-m machine]: the target machine to be built.
    * [-b path]:    non-default path of project build folder.
    * [-e layers]:  extra layer names
    * [-D distro]:  override the default distro selection ($DEFAULT_DISTRO)
    * [-j jobs]:    number of jobs for make to spawn during the compilation stage.
    * [-t tasks]:   number of BitBake tasks that can be issued in parallel.
    * [-d path]:    non-default path of DL_DIR (downloaded source)
    * [-c path]:    non-default path of SSTATE_DIR (shared state Cache)
    * [-l]:         lite mode. To help conserve disk space, deletes the building
                    directory once the package is built.
    * [-h]:         help
"
    if [ "`readlink $SHELL`" = "dash" ];then
        echo "
    You are using dash which does not pass args when being sourced.
    To workaround this limitation, use \"set -- args\" prior to
    sourcing this script. For exmaple:
        \$ set -- -m s32g274ardb2 -j 3 -t 2
        \$ . $ROOT_DIR/$PROG_NAME
"
    fi
}

add_layers_for_machines()
{
    # add the layer specified in PARAM_LAYER_LIST only for the machines
    # contained in PARAM_MACHINE_LIST

    PARAM_LAYER_LIST=$1
    PARAM_MACHINE_LIST=$2

    echo ${MACHINE} | egrep -q "${PARAM_MACHINE_LIST}"
    if [ $? -eq 0 ]; then
        for layer in $(eval echo ${PARAM_LAYER_LIST}); do
            if [ -e "${ROOTDIR}/${SOURCESDIR}/${layer}" ]; then
                LAYER_LIST="$LAYER_LIST \
                    $layer \
                "
            fi
        done
    fi
}

is_not_ubuntu_machine()
{
    echo ${MACHINE} | egrep -q "${UBUNTU_MACHINE}"
    return $?
}

# parse the parameters
# initialize option variables to avoid 'unbound variable' when set -u is active
setup_error=''
setup_h=''
setup_j=''
setup_t=''
setup_builddir=''
setup_download=''
extra_layers=''
distro_override=''
setup_sstate=''
setup_l=''
OLD_OPTIND=$OPTIND
while getopts "m:j:t:b:d:e:D:c:lh" setup_flag
do
    case $setup_flag in
        m) MACHINE="$OPTARG";
           ;;
        j) setup_j="$OPTARG";
           ;;
        t) setup_t="$OPTARG";
           ;;
        b) setup_builddir="$OPTARG";
           ;;
        d) setup_download="$OPTARG";
           ;;
        e) extra_layers="$OPTARG";
           ;;
        D) distro_override="$OPTARG";
           ;;
        c) setup_sstate="$OPTARG";
           ;;
        l) setup_l='true';
           ;;
        h) setup_h='true';
           ;;
        ?) setup_error='true';
           ;;
    esac
done
OPTIND=$OLD_OPTIND

OE_LAYER_LIST="\
    $YOCTO_LAYER_ROOT_DIR/meta-openembedded/meta-oe \
    $YOCTO_LAYER_ROOT_DIR/meta-openembedded/meta-multimedia \
    $YOCTO_LAYER_ROOT_DIR/meta-openembedded/meta-python \
    $YOCTO_LAYER_ROOT_DIR/meta-openembedded/meta-networking \
    $YOCTO_LAYER_ROOT_DIR/meta-openembedded/meta-gnome \
    $YOCTO_LAYER_ROOT_DIR/meta-openembedded/meta-filesystems \
    $YOCTO_LAYER_ROOT_DIR/meta-openembedded/meta-webserver \
    $YOCTO_LAYER_ROOT_DIR/meta-openembedded/meta-perl \
    $YOCTO_LAYER_ROOT_DIR/meta-openembedded/meta-xfce \
    $YOCTO_LAYER_ROOT_DIR/meta-openembedded/meta-initramfs \
    $YOCTO_LAYER_ROOT_DIR/meta-arm/meta-arm \
    $YOCTO_LAYER_ROOT_DIR/meta-arm/meta-arm-bsp \
    $YOCTO_LAYER_ROOT_DIR/meta-arm/meta-arm-systemready \
    $YOCTO_LAYER_ROOT_DIR/meta-arm/meta-arm-toolchain \
    $YOCTO_LAYER_ROOT_DIR/meta-clang \
"

COMMON_LAYER_LIST=" \
    $COMMON_LAYER_ROOT_DIR/meta-virtualization \
    $COMMON_LAYER_ROOT_DIR/meta-timesys \
    $COMMON_LAYER_ROOT_DIR/meta-security \
    $COMMON_LAYER_ROOT_DIR/meta-browser/meta-chromium \
    $COMMON_LAYER_ROOT_DIR/meta-browser/meta-firefox \
    $COMMON_LAYER_ROOT_DIR/meta-qt6 \
"

FSL_LAYER_LIST=" \
    $FSL_LAYER_ROOT_DIR/meta-freescale \
    $FSL_LAYER_ROOT_DIR/meta-freescale-3rdparty \
    $FSL_LAYER_ROOT_DIR/meta-freescale-distro \
"

NXP_LAYER_LIST=" \
    $NXP_LAYER_ROOT_DIR/meta-imx/meta-imx-bsp \
    $NXP_LAYER_ROOT_DIR/meta-imx/meta-imx-cockpit \
    $NXP_LAYER_ROOT_DIR/meta-imx/meta-imx-ml \
    $NXP_LAYER_ROOT_DIR/meta-imx/meta-imx-sdk \
    $NXP_LAYER_ROOT_DIR/meta-imx/meta-imx-v2x \
    $NXP_LAYER_ROOT_DIR/meta-nxp-demo-experience \
    $NXP_LAYER_ROOT_DIR/meta-nxp-connectivity/meta-nxp-matter-baseline \
    $NXP_LAYER_ROOT_DIR/meta-nxp-connectivity/meta-nxp-openthread \
    $NXP_LAYER_ROOT_DIR/meta-nxp-connectivity/meta-nxp-otbr \
    $NXP_LAYER_ROOT_DIR/meta-nxp-connectivity/meta-nxp-matter-advanced \
    $NXP_LAYER_ROOT_DIR/meta-nxp-connectivity/meta-nxp-connectivity-examples \
    $NXP_LAYER_ROOT_DIR/meta-nxp-connectivity/meta-nxp-zigbee-rcp \
"

META_ALPHA_LAYER=" \
    $SOURCES_DIR/meta-alpha \
"

LAYER_LIST=" \
    $OE_LAYER_LIST \
    $COMMON_LAYER_LIST \
    $FSL_LAYER_LIST \
    $NXP_LAYER_LIST \
    $META_ALPHA_LAYER \
"

# check the "-h" and other not supported options
if test $setup_error || test $setup_h; then
    usage && clean_up && return
fi

# initialise DISTRO to avoid unbound variable under 'set -u'
DISTRO=''
if [ -n "$distro_override" ]; then
    DISTRO="$distro_override";
fi

if [ -z "$DISTRO" ]; then
    DISTRO="$DEFAULT_DISTRO"
fi

# Check the machine type specified
# Note that we intentionally do not test ${MACHINEEXCLUSION}
# initialize MACHINE_LAYER to avoid unbound variable under 'set -u'
# MACHINE_LAYER=''
# if [ -n "${MACHINE}" ]; then
#     for layer in $(eval echo $LAYER_LIST); do
#         if [ -e $${layer}/conf/machine/${MACHINE}.conf ]; then
#             MACHINE_LAYER="${layer}"
#             break
#         fi
#     done
# else
#     usage && clean_up && return $EINVAL
# fi

# if [ -n "${MACHINE_LAYER}" ]; then 
#     echo "Configuring for ${MACHINE} and distro ${DISTRO}..."
# else
#     echo -e "\nThe \$MACHINE you have specified ($MACHINE) is not supported by this build setup."
#     usage && clean_up && return $EINVAL
# fi

# set default jobs and threads
CPUS=`grep -c processor /proc/cpuinfo`
JOBS="$(( ${CPUS} * 3 / 2))"
THREADS="$(( ${CPUS} * 2 ))"

# check optional jobs and threads
if echo "$setup_j" | egrep -q "^[0-9]+$"; then
    JOBS=$setup_j
fi
if echo "$setup_t" | egrep -q "^[0-9]+$"; then
    THREADS=$setup_t
fi

# set project folder location and name
if [ -n "$setup_builddir" ]; then
    if echo "$setup_builddir" | grep -q ^/; then
        PROJECT_DIR="${setup_builddir}"
    else
        PROJECT_DIR="`pwd`/${setup_builddir}"
    fi
else
    PROJECT_DIR=${ROOT_DIR}/build_${MACHINE}
fi
# create project dir (guarded)
if ! mkdir -p "$PROJECT_DIR"; then
    echo "ERROR: cannot create project dir $PROJECT_DIR" >&2
    clean_up && return $EINVAL
fi

if [ -n "$setup_download" ]; then
    if echo "$setup_download" | grep -q ^/; then
        DOWNLOADS="${setup_download}"
    else
        DOWNLOADS="`pwd`/${setup_download}"
    fi
else
    DOWNLOADS="$ROOT_DIR/downloads"
fi
# create downloads dir (guarded)
if ! mkdir -p "$DOWNLOADS"; then
    echo "ERROR: cannot create downloads dir $DOWNLOADS" >&2
    clean_up && return
fi
if download_res=$(readlink -f "$DOWNLOADS" 2>/dev/null); then
    DOWNLOADS="$download_res"
else
    echo "WARNING: readlink -f failed for $DOWNLOADS, using literal path" >&2
fi

if [ -n "$setup_sstate" ]; then
    if echo "$setup_sstate" | grep -q ^/; then
        CACHES="${setup_sstate}"
    else
        CACHES="`pwd`/${setup_sstate}"
    fi
else
    # is_not_ubuntu_machine
    # if [ $? -eq 1 ]; then
        CACHES="$PROJECT_DIR/sstate-cache"
    # else
    #     CACHES="$PROJECT_DIR/sstate-cache-ubuntu"
    # fi
fi
# create caches dir (guarded)
if ! mkdir -p "$CACHES"; then
    echo "ERROR: cannot create sstate cache dir $CACHES" >&2
    clean_up && return $EINVAL
fi
if cache_res=$(readlink -f "$CACHES" 2>/dev/null); then
    CACHES="$cache_res"
else
    echo "WARNING: readlink -f failed for $CACHES, using literal path" >&2
fi

# check if project folder was created before
if [ -e "$PROJECT_DIR/SOURCE_THIS" ]; then
    echo "$PROJECT_DIR was created before."
    if ! . "$PROJECT_DIR/SOURCE_THIS"; then
        echo "ERROR: failed to source $PROJECT_DIR/SOURCE_THIS" >&2
        clean_up && return $EINVAL
    fi
    echo "Nothing is changed."
    clean_up && return $EINVAL
fi

# source oe-init-build-env to init build env
# Guard cd and the sourced oe-init-build-env so that if something fails
# we return instead of letting 'set -e' terminate the interactive shell
if ! cd "$OE_ROOT_DIR"; then
    echo "ERROR: cannot change directory to $OE_ROOT_DIR" >&2
    clean_up && return
fi
set -- $PROJECT_DIR
if ! . ./oe-init-build-env > /dev/null; then
    echo "ERROR: oe-init-build-env failed" >&2
    clean_up && cd "$ROOT_DIR" && return $EINVAL
fi

# if conf/local.conf not generated, no need to go further
if [ ! -e conf/local.conf ]; then
    echo "ERROR: the local.conf is not created, Exit ..."
    clean_up && cd $ROOT_DIR && return
fi

# Remove comment lines and empty lines
if ! sed -i -e '/^#.*/d' -e '/^$/d' conf/local.conf; then
    echo "ERROR: failed to clean conf/local.conf" >&2
    clean_up && cd "$ROOT_DIR" && return
fi

# Change settings according to the environment
if ! sed -e "s,MACHINE ??=.*,MACHINE ??= '$MACHINE',g" \
        -e "s,SDK_MACHINE ??=.*,SDK_MACHINE ??= '$SDK_MACHINE',g" \
        -e "s,DISTRO ?=.*,DISTRO ?= '$DISTRO',g" \
        -i conf/local.conf; then
    echo "ERROR: failed to update conf/local.conf with MACHINE/DISTRO" >&2
    clean_up && cd "$ROOT_DIR" && return
fi

# Clean up PATH, because if it includes tokens to current directories somehow,
# wrong binaries can be used instead of the expected ones during task execution
export PATH="`echo $PATH | sed 's/\(:.\|:\)*:/:/g;s/^.\?://;s/:.\?$//'`"

# add layers
for layer in $(eval echo $LAYER_LIST); do
    append_layer=""
    if [ -e ${layer} ]; then
        append_layer="${layer}"
    fi
    if [ -n "${append_layer}" ]; then
        append_layer=`readlink -f $append_layer`
        if ! awk '/  "/ && !x {print "'"  ${append_layer}"' \\"; x=1} 1' \
            conf/bblayers.conf > conf/bblayers.conf~; then
            echo "ERROR: failed to update conf/bblayers.conf for layer $append_layer" >&2
            clean_up && return
        fi
        if ! mv conf/bblayers.conf~ conf/bblayers.conf; then
            echo "ERROR: failed to move updated bblayers.conf~" >&2
            clean_up && return
        fi

        # check if layer is compatible with supported yocto version.
        # if not, make it so.
        conffile_path="${append_layer}/conf/layer.conf"
        if [ -e "${conffile_path}" ]; then
            if ! yocto_compatible=$(grep "LAYERSERIES_COMPAT" "${conffile_path}" | grep "${YOCTO_VERSION}" 2>/dev/null); then
                yocto_compatible=''
            fi
            if [ -z "${yocto_compatible}" ]; then
                if ! sed -E "/LAYERSERIES_COMPAT/s/(\".*)\"/\1 $YOCTO_VERSION\"/g" -i "${conffile_path}"; then
                    echo "WARNING: failed to patch LAYERSERIES_COMPAT in ${conffile_path}" >&2
                else
                    echo Layer ${layer} updated for ${YOCTO_VERSION}.
                fi
            fi
        else
            echo "WARNING: layer conf file not found: ${conffile_path}" >&2
        fi
    fi
done

cat >> conf/local.conf <<-EOF

# Parallelism Options
BB_NUMBER_THREADS = "$THREADS"
PARALLEL_MAKE = "-j $JOBS"
DL_DIR = "$DOWNLOADS"
SSTATE_DIR = "$CACHES"
EOF

for s in $HOME/.oe $HOME/.yocto; do
    if [ -e "$s/site.conf" ]; then
        echo "Linking $s/site.conf to conf/site.conf"
        if ! ln -s "$s/site.conf" conf 2>/dev/null; then
            echo "WARNING: failed to link $s/site.conf to conf/site.conf (maybe already linked)" >&2
        fi
    fi
done

# option to enable lite mode for now
if test $setup_l; then
    if ! echo "# delete sources after build" >> conf/local.conf; then
        echo "WARNING: failed to append rm_work to conf/local.conf" >&2
    fi
    if ! echo "INHERIT += \"rm_work\"" >> conf/local.conf; then
        echo "WARNING: failed to append rm_work inherit to conf/local.conf" >&2
    fi
    echo >> conf/local.conf || true
fi

if echo "$MACHINE" | egrep -q "^(b4|p5|t1|t2|t4)"; then
    # disable prelink (for multilib scenario) for now
    if ! sed -i s/image-mklibs.image-prelink/image-mklibs/g conf/local.conf; then
        echo "WARNING: failed to modify prelink setting in conf/local.conf" >&2
    fi
fi


# make a SOURCE_THIS file
if [ ! -e SOURCE_THIS ]; then
    if ! echo "#!/bin/sh" >> SOURCE_THIS; then
        echo "WARNING: failed to write SOURCE_THIS" >&2
    else
        echo "cd $OE_ROOT_DIR" >> SOURCE_THIS || true
        echo "set -- $PROJECT_DIR" >> SOURCE_THIS || true
        echo ". ./oe-init-build-env > /dev/null" >> SOURCE_THIS || true
        echo "echo \"Back to build project $PROJECT_DIR.\"" >> SOURCE_THIS || true
    fi
fi

prompt_message
if ! cd "$PROJECT_DIR"; then
    echo "WARNING: cannot cd to $PROJECT_DIR" >&2
else
    clean_up
fi
