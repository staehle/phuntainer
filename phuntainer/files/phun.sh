#!/bin/bash
set -ex

DEFAULT_UID=4321
USERNAME=ph

CONF_DIR=/config
PHAB_DIR=/phabricator
REPO_DIR=/var/repo
EXAMPLE_CONFIG_DIR=${PHAB_DIR}/conf/example/

PHAB_LOCAL_JSON=${CONF_DIR}/local/local.json
PHAB_PREAMBLE=${CONF_DIR}/preamble.php
PHAB_SSH_CONF=${CONF_DIR}/sshd_config

PHAB_SSH_SHHH=${CONF_DIR}/ssh-secret
PHAB_SSH_HOOK=${PHAB_SSH_SHHH}/phabricator-ssh-hook.sh

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
# chown -R ${USERNAME}:${USERNAME} /libphutil
# chown -R ${USERNAME}:${USERNAME} /arcanist
# chown -R ${USERNAME}:${USERNAME} /phabricator
# chown -R ${USERNAME}:${USERNAME} /PHPExcel
chown -R ${USERNAME}:${USERNAME} ${REPO_DIR}

# Configurations
sudo -u ${USERNAME} mkdir -p /config/local
sudo -u ${USERNAME} mkdir -p /config/extensions
if [ ! -f ${PHAB_LOCAL_JSON} ]; then
    sudo -u ${USERNAME} cp ${EXAMPLE_CONFIG_DIR}/local.json ${PHAB_LOCAL_JSON}
fi
if [ ! -f ${PHAB_PREAMBLE} ]; then
    sudo -u ${USERNAME} cp ${EXAMPLE_CONFIG_DIR}/preamble.php ${PHAB_PREAMBLE}
fi
if [ ! -f ${PHAB_SSH_CONF} ]; then
    sudo -u ${USERNAME} cp ${EXAMPLE_CONFIG_DIR}/sshd_config ${PHAB_SSH_CONF}
fi
# NOTE: The phabricator-ssh-hook.sh file MUST be owned by root with 755 perms or SSHD will refuse it.
mkdir -p ${PHAB_SSH_SHHH}
if [ ! -f ${PHAB_SSH_HOOK} ]; then
    sudo cp ${EXAMPLE_CONFIG_DIR}/phabricator-ssh-hook.sh ${PHAB_SSH_HOOK}
fi
chown root:root -R ${PHAB_SSH_SHHH}
chmod 755 ${PHAB_SSH_HOOK}

# Make sure symlinks exist:
# conf/local
rm -rf ${PHAB_DIR}/conf/local
ln -s ${CONF_DIR}/local ${PHAB_DIR}/conf/local
# preamble.php
rm -f ${PHAB_DIR}/support/preamble.php
ln -s ${PHAB_PREAMBLE} ${PHAB_DIR}/support/preamble.php

echo "SQL server config:"
${PHAB_DIR}/bin/config get mysql.host

echo "Running SQL Checks"
# ping phabsql -c 3
${PHAB_DIR}/bin/storage upgrade --force

echo "Starting SSH Services"
mkdir -p /run/ssh
/usr/sbin/sshd -f ${PHAB_SSH_CONF} -E/var/log/sshd_phabricator

echo "Starting Phabricator"
sudo -u ${USERNAME} ${PHAB_DIR}/bin/phd start
apache2-foreground
