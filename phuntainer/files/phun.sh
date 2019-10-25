#!/bin/bash
set -ex

ROOT_DIR=/phab
PHAB_DIR=${ROOT_DIR}/phabricator

if [[ "${UPGRADE_ON_BOOT}" == "true" ]]; then
    cd ${ROOT_DIR}/libphutil && git pull
    cd ${ROOT_DIR}/arcanist && git pull
    cd ${ROOT_DIR}/phabricator && git pull
fi

echo "<?php ${PREAMBLE_SCRIPT} ?>" > ${PHAB_DIR}/support/preamble.php
chmod +x ${PHAB_DIR}/support/preamble.php

PHAB_DEFAULT_JSON=${PHAB_DIR}/conf/local/local.default
PHAB_LOCAL_JSON=${PHAB_DIR}/conf/local/local.json

if [ ! -f ${PHAB_LOCAL_JSON} ]; then
    cp -f ${PHAB_DEFAULT_JSON} ${PHAB_LOCAL_JSON}
fi

${PHAB_DIR}/bin/storage upgrade --force
${PHAB_DIR}/bin/phd start
apache2-foreground
