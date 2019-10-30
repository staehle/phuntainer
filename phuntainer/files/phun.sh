#!/bin/bash
set -ex

PHAB_DIR=/phabricator

if [ -z "${DO_NOT_UPGRADE_ON_BOOT}" ]; then
    git -C /libphutil pull
    git -C /arcanist pull
    git -C /phabricator pull
fi

#echo "<?php ${PREAMBLE_SCRIPT} ?>" > ${PHAB_DIR}/support/preamble.php
#chmod +x ${PHAB_DIR}/support/preamble.php

PHAB_LOCAL_JSON=${PHAB_DIR}/conf/local/local.json
if [ ! -f ${PHAB_LOCAL_JSON} ]; then
    echo "Error: local.json not bind-mounted to: '${PHAB_LOCAL_JSON}'"
	exit 1
fi

echo "SQL server config:"
${PHAB_DIR}/bin/config get mysql.host

ping phabsql -c 5

${PHAB_DIR}/bin/storage upgrade --force
${PHAB_DIR}/bin/phd start
apache2-foreground
