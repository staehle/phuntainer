#!/bin/bash
set -ex

DEFAULT_UID=2123
PHAB_USERNAME=phabricator

ROOT_DIR=/
PHAB_DIR=${ROOT_DIR}/phabricator
PHAB_LOCAL_JSON=${PHAB_DIR}/conf/local/local.json
REPO_DIR=/var/repo

if [ -z "${DO_NOT_UPGRADE_ON_BOOT}" ]; then
    git -C ${ROOT_DIR}/libphutil pull
    git -C ${ROOT_DIR}/arcanist pull
    git -C ${ROOT_DIR}/phabricator pull
fi

if [ ! -f ${PHAB_LOCAL_JSON} ]; then
    echo "Error: local.json not bind-mounted to: '${PHAB_LOCAL_JSON}'"
	exit 1
fi
if [ ! -d ${REPO_DIR} ]; then
    echo "Error: ${REPO_DIR} was not bind-mounted!"
    exit 1
fi

# Update UID/GID
if [ ! -z "${PUID}" ]; then
    if [ -z "${GUID}" ]; then
        # If group not specified, use PID
        GUID=$PUID
    fi
    sed -i "s/phabricator/"
fi

chown phabricator:phabricator /var/repo

echo "SQL server config:"
${PHAB_DIR}/bin/config get mysql.host

ping phabsql -c 5

${PHAB_DIR}/bin/storage upgrade --force
${PHAB_DIR}/bin/phd start
apache2-foreground
