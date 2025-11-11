*********************************imx6ull 14x14 alpha*********************************

- create build directory
source yocto-bsp-setup.sh -m imx6ull14x14alpha -D distro-imx6ull-fb

- fetch package tarball
bitbake imx6ull-image-qt --runall=do_fetch

- Add the following lines in conf/local.conf file from the build directory.
BB_NO_NETWORK = "1"
BB_SRCREV_POLICY = "cache"

- build
bitbake imx6ull-image-qt -c clean && bitbake imx6ull-image-qt



