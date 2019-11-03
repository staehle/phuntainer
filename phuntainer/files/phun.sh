#!/bin/bash
set -ex

DEFAULT_UID=4321
DEFAULT_USERNAME=phabricator

CONF_DIR=/config
PHAB_DIR=/phabricator
PHAB_LOCAL_JSON=${PHAB_DIR}/conf/local/local.json
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
if [ -z "${USERNAME}" ]; then
    USERNAME=${DEFAULT_USERNAME}
fi

# Set given user/id values
sed -i "s/phabricator:x:4321:4321/${USERNAME}:x:${PUID}:${GUID}/g" /etc/passwd
sed -i "s/phabricator:!:4321:phabricator,/${USERNAME}:!:${GUID}:${USERNAME},/g" /etc/group
echo "USER/ID/GID values:"
cat /etc/passwd | grep ${USERNAME}
cat /etc/group | grep ${USERNAME}
echo

# Give ownership of directories
chown -R ${USERNAME}:${USERNAME} /libphutil
chown -R ${USERNAME}:${USERNAME} /arcanist
chown -R ${USERNAME}:${USERNAME} /phabricator
chown -R ${USERNAME}:${USERNAME} /PHPExcel
chown -R ${USERNAME}:${USERNAME} ${REPO_DIR}

# Configurations
if [ ! -f ${PHAB_LOCAL_JSON} ]; then
    echo "local.json not found! Copying default to: '${PHAB_LOCAL_JSON}'"
    mkdir -p /config/local
	cp ${PHAB_DIR}/conf/example/local.conf /config/local/local.json
    if [ ! -f ${PHAB_LOCAL_JSON} ]; then
        echo "ayyy the symlink at /phabricator/conf/local to /config/local broke"
    fi
fi

echo "SQL server config:"
${PHAB_DIR}/bin/config get mysql.host

ping phabsql -c 5

${PHAB_DIR}/bin/storage upgrade --force
sudo -u ${USERNAME} ${PHAB_DIR}/bin/phd start
apache2-foreground
