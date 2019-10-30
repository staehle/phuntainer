#!/bin/bash
# set these two variables:
PHAB_NETWORK_NAME=phabnet
HOST_STORAGE_PATH=/opt/phabricator

### do not edit past this line
if [[ -z "${PHAB_NETWORK_NAME}" || -z "${HOST_STORAGE_PATH}" ]]; then
    echo "You did not set the variables in this script!"
    exit 1
fi

if [ ! -f ${HOST_STORAGE_PATH}/local.json ]; then
    echo "You did not create a Phabricator config at '${HOST_STORAGE_PATH}/local.json'!"
    exit 1
fi

docker network inspect ${PHAB_NETWORK_NAME} >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
    # Create the network
    docker network create ${PHAB_NETWORK_NAME}
fi

echo "Cleaning previous containers"
docker stop phabricator
docker stop phabsql
docker rm phabricator
docker rm phabsql

if [[ "$1" == "clean" ]]; then
    exit
fi

set -eu

echo "Starting MariaDB"
docker run -d \
    --name phabsql \
    --network ${PHAB_NETWORK_NAME} \
    --restart=unless-stopped \
    -e MYSQL_ROOT_PASSWORD=rpass12345 \
    -v ${HOST_STORAGE_PATH}/sql:/var/lib/mysql \
    mariadb:10.4 --local-infile=0 --max_allowed_packet=64M

echo "For some reason, need to wait 60 seconds for MariaDB to start"
echo "Waiting for MariaDB to initialize..."
sleep 10
echo "50 seconds remaining..."
sleep 10
echo "40 seconds remaining..."
sleep 10
echo "30 seconds remaining..."
sleep 10
echo "20 seconds remaining..."
sleep 10
echo "10 seconds remaining..."
sleep 10

echo
echo "Starting Phuntainer"
docker run -d \
    --name phabricator \
    --network ${PHAB_NETWORK_NAME} \
    --restart=unless-stopped \
    -p 80:80 \
    -p 443:443 \
    -v ${HOST_STORAGE_PATH}/local.json:/phabricator/conf/local/local.json \
    -v ${HOST_STORAGE_PATH}/extensions:/phabricator/src/extensions \
    -v ${HOST_STORAGE_PATH}/repodata:/var/repo \
    staehle/phuntainer:latest

echo "Done!"