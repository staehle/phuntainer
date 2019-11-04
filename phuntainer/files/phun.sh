#!/bin/bash
set -ex

DEFAULT_UID=4321
USERNAME=ph

CONF_DIR=/config
PHAB_DIR=/phabricator
PHAB_LOCAL_JSON=${CONF_DIR}/local/local.json
PHAB_PREAMBLE=${CONF_DIR}/preamble.php
REPO_DIR=/var/repo

if [ -z "${DO_NOT_UPGRADE_ON_BOOT}" ]; then
    git -C /libphutil pull
    git -C /arcanist pull
    git -C /phabricator pull
fi

if [ ! -d ${REPO_DIR} ]; then
    echo "Error: ${REPO_DIR} was not bind-mounted!"
    exit 1
fi
if [ ! -d ${CONF_DIR} ]; then
    echo "Error: ${CONF_DIR} was not bind-mounted!"
    exit 1
fi

# Update UID/GID for given username
if [ ! -z "${PUID}" ]; then
    if [ -z "${GUID}" ]; then
        # If group not specified, use PID
        GUID=$PUID
    fi
else
    PUID=${DEFAULT_UID}
    GUID=${DEFAULT_UID}
fi
# if [ -z "${USERNAME}" ]; then
#     USERNAME=${DEFAULT_USERNAME}
# fi

# Set given user/id values
sed -i "s/${USERNAME}:x:4321:4321/${USERNAME}:x:${PUID}:${GUID}/g" /etc/passwd
sed -i "s/${USERNAME}:!:4321:/${USERNAME}:!:${GUID}:/g" /etc/group
echo "USER/ID/GID values:"
cat /etc/passwd | grep ${USERNAME}:
cat /etc/group | grep ${USERNAME}:
echo

# Give ownership of directories
chown -R ${USERNAME}:${USERNAME} /libphutil
chown -R ${USERNAME}:${USERNAME} /arcanist
chown -R ${USERNAME}:${USERNAME} /phabricator
chown -R ${USERNAME}:${USERNAME} /PHPExcel
chown -R ${USERNAME}:${USERNAME} ${REPO_DIR}

# Configurations
sudo -u ${USERNAME} mkdir -p /config/local
sudo -u ${USERNAME} mkdir -p /config/extensions
if [ ! -f ${PHAB_LOCAL_JSON} ]; then
    sudo -u ${USERNAME} cp ${PHAB_DIR}/conf/example/local.json ${PHAB_LOCAL_JSON}
fi
if [ ! -f ${PHAB_PREAMBLE} ]; then
    sudo -u ${USERNAME} cp ${PHAB_DIR}/conf/example/preamble.php ${PHAB_PREAMBLE}
fi
# Make sure symlinks exist
rm -rf ${PHAB_DIR}/conf/local
rm -f ${PHAB_DIR}/support/preamble.php
sudo -u ${USERNAME} ln -s ${CONF_DIR}/local ${PHAB_DIR}/conf/local
sudo -u ${USERNAME} ln -s ${PHAB_PREAMBLE} ${PHAB_DIR}/support/preamble.php

echo "SQL server config:"
${PHAB_DIR}/bin/config get mysql.host

ping phabsql -c 5

${PHAB_DIR}/bin/storage upgrade --force
sudo -u ${USERNAME} ${PHAB_DIR}/bin/phd start
apache2-foreground
