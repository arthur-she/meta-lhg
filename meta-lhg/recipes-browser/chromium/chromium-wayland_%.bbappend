PACKAGECONFIG_append = " ${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'use-ocdm', '', d)}  proprietary-codecs"
PACKAGECONFIG[use-ocdm] = ""


OCDM_GIT_BRANCH="chromium-53.0.2785.143"
OCDM_DESTSUFIX="ocdm"
EXTERNAL_OCDM_DESTSUFIX="media/cdm/ppapi/external_open_cdm"

#This is deliberately separated from CHROMIUM_BUILD_TYPE so we can
#easily enable debug builds of just the OpenCDM plugin for symbolic
#debugging using --ppapi-plugin-launcher='gdbserver localhost:4444'
OCDM_CHROMIUM_BUILD_TYPE="Release"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "${@bb.utils.contains('PACKAGECONFIG', 'use-ocdm', '\
    git://github.com/linaro-home/open-content-decryption-module.git;protocol=https;branch=${OCDM_GIT_BRANCH};name=ocdm;destsuffix=${OCDM_DESTSUFIX}\
    ', '', d)}"
SRC_URI += "http://gsdview.appspot.com/chromium-browser-official/chromium-${PV}-testdata.tar.xz;name=testdata \
	    file://Fix_PPAPI_build_fails_on_aarch64.patch \
        file://Chromium-OCDM-tests-chrome_tests_gypi.patch \
           "

SRC_URI[testdata.md5sum] = "3345ec8dc4066e92426c28c61d006d9c"
SRC_URI[testdata.sha256sum] = "62f218b9b703177af7c39682dbf2aeb67c424ac8c068c0f70d8325a53e3c1c40"

SRCREV_ocdm = "${AUTOREV}"
DEPENDS_append = " ${@bb.utils.contains('PACKAGECONFIG', 'use-ocdm', 'ocdmi', '', d)} "

python add_ocdm_patches() {
    srcdir = d.getVar('WORKDIR', True)
    d.appendVar('SRC_URI', " file://" + srcdir + "/ocdm/patch/add_ocdm_keyssystems.patch")
    d.appendVar('SRC_URI', " file://" + srcdir + "/ocdm/patch/add_playready_keysystem.patch")
}

copy_ocdm_files() {
    cp -r ${WORKDIR}/ocdm ${S}/${EXTERNAL_OCDM_DESTSUFIX}
    ln -s ${S}/media/cdm/ppapi/external_open_cdm/src/browser/chrome/tests/data ${S}/chrome/test/data/media/drmock
}

do_patch[prefuncs] += "${@bb.utils.contains('PACKAGECONFIG', 'use-ocdm', 'add_ocdm_patches', '', d)}"
do_unpack[postfuncs] += "${@bb.utils.contains('PACKAGECONFIG', 'use-ocdm', 'copy_ocdm_files', '', d)}"

do_compile_append() {
    if [ -n "${@bb.utils.contains('PACKAGECONFIG', 'use-ocdm', 'use-ocdm', '', d)}" ]; then
        ninja -C ${S}/out/${OCDM_CHROMIUM_BUILD_TYPE} opencdmadapter
        ninja -C out/${CHROMIUM_BUILD_TYPE} ${PARALLEL_MAKE}  browser_tests
    fi
}

do_install_append() {
    if [ -n "${@bb.utils.contains('PACKAGECONFIG', 'use-ocdm', 'use-ocdm', '', d)}" ]; then
        install -Dm 0755 ${B}/out/${OCDM_CHROMIUM_BUILD_TYPE}/libopencdmadapter.so \
            ${D}${libdir}/${BPN}/libopencdmadapter.so
        install -Dm 0755 ${B}/out/${OCDM_CHROMIUM_BUILD_TYPE}/libopencdm.so \
            ${D}${libdir}/${BPN}/libopencdm.so
        install -Dm 0755 ${B}/out/${CHROMIUM_BUILD_TYPE}/browser_tests ${D}${bindir}/${BPN}/test/out/${CHROMIUM_BUILD_TYPE}/browser_tests
        install -Dm 0644 ${B}/chrome/test/data/media/drmock/test.html  ${D}${bindir}/${BPN}/test/chrome/test/data/media/drmock/test.html
    fi
}
