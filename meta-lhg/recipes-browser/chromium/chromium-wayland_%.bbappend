PACKAGECONFIG_append = " ${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'use-ocdm', '', d)}  proprietary-codecs"
PACKAGECONFIG[use-ocdm] = ""


OCDM_GIT_BRANCH="chromium-53.0.2785.143"
OCDM_DESTSUFIX="ocdm"
EXTERNAL_OCDM_DESTSUFIX="media/cdm/ppapi/external_open_cdm"

#This is deliberately separated from CHROMIUM_BUILD_TYPE so we can
#easily enable debug builds of just the OpenCDM plugin for symbolic
#debugging using --ppapi-plugin-launcher='gdbserver localhost:4444'
OCDM_CHROMIUM_BUILD_TYPE="Release"

SRC_URI += "${@bb.utils.contains('PACKAGECONFIG', 'use-ocdm', '\
    git://github.com/linaro-home/open-content-decryption-module.git;protocol=https;branch=${OCDM_GIT_BRANCH};name=ocdm;destsuffix=${OCDM_DESTSUFIX}\
    ', '', d)}"
SRCREV_ocdm = "${AUTOREV}"
DEPENDS_append = " ${@bb.utils.contains('PACKAGECONFIG', 'use-ocdm', 'ocdmi', '', d)} "

python add_ocdm_patches() {
    srcdir = d.getVar('WORKDIR', True)
    d.appendVar('SRC_URI', " file://" + srcdir + "/ocdm/patch/add_ocdm_keyssystems.patch")
    d.appendVar('SRC_URI', " file://" + srcdir + "/ocdm/patch/add_playready_keysystem.patch")
}

copy_ocdm_files() {
    cp -r ${WORKDIR}/ocdm ${S}/${EXTERNAL_OCDM_DESTSUFIX}
}

do_patch[prefuncs] += "${@bb.utils.contains('PACKAGECONFIG', 'use-ocdm', 'add_ocdm_patches', '', d)}"
do_unpack[postfuncs] += "${@bb.utils.contains('PACKAGECONFIG', 'use-ocdm', 'copy_ocdm_files', '', d)}"

do_compile_append() {
    if [ -n "${@bb.utils.contains('PACKAGECONFIG', 'use-ocdm', 'use-ocdm', '', d)}" ]; then
        ninja -C ${S}/out/${OCDM_CHROMIUM_BUILD_TYPE} opencdmadapter
    fi
}

do_install_append() {
    if [ -n "${@bb.utils.contains('PACKAGECONFIG', 'use-ocdm', 'use-ocdm', '', d)}" ]; then
        install -Dm 0755 ${B}/out/${OCDM_CHROMIUM_BUILD_TYPE}/libopencdmadapter.so \
            ${D}${libdir}/${BPN}/libopencdmadapter.so
        install -Dm 0755 ${B}/out/${OCDM_CHROMIUM_BUILD_TYPE}/libopencdm.so \
            ${D}${libdir}/${BPN}/libopencdm.so
    fi
}
