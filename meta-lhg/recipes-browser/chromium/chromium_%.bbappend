# chromium_45 fails to work with newer version of nns which is used in krogoth
PREFERRED_VERSION_nss = "3.19.%"

PACKAGECONFIG_append = " ${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'use-ocdm', '', d)} proprietary-codecs"
