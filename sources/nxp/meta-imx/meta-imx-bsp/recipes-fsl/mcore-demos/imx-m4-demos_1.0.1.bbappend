# Override do_deploy to change deploy path
DEPLOY_FILE_EXT       = "bin"

do_deploy () {
    # Install the demo binaries
    install -d ${DEPLOYDIR}/mcore-demos
    install -m 0644 ${S}/*.${DEPLOY_FILE_EXT} ${DEPLOYDIR}/mcore-demos/
}
