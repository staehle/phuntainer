# phuntainer
_(noun)_ A Fun Container for Phabricator! This is a Docker image that provides a ready-to-run Phabricator instance, with minimal user setup.

This container auto-updates with the latest "stable" branch source from the following official Phacility (maintainer of Phabricator) repositories:

* [GitHub: Phacility/Phabricator](https://github.com/phacility/phabricator.git)
* [GitHub: Phacility/libphutil](https://github.com/phacility/libphutil.git)
* [GitHub: Phacility/Arcanist](https://github.com/phacility/arcanist.git)

## Using phuntainer

This is assuming a manual setup. The following could be converted to a Docker Compose fairly easy -- some assembly required there.

### Docker Network

Create a new Docker network:
```
$ PHAB_NETWORK_NAME=network-phabricator
$ docker network create ${PHAB_NETWORK_NAME}
```

Alternatively, replace the PHAB_NETWORK_NAME variable in the following commands with an existing Docker network you wish to use.

### Storage -- Host filesystem and MySQL server

Define some path on the host machine to store data for both the SQL Database and Phabricator:
```
$ HOST_STORAGE_PATH=/some/host/path
```

Create a MariaDB container:
```
$ docker run -d \
    --name phabsql \
    --network ${PHAB_NETWORK_NAME} \
    --restart=unless-stopped \
    -e MYSQL_ROOT_PASSWORD=rpass12345 \
    -v ${HOST_STORAGE_PATH}/sql:/var/lib/mysql \
    mariadb:10.4 --local-infile=0 --max_allowed_packet=64M
```

Replace '${HOST_STORAGE_PATH}/sql' with a path to where you want the SQL storage to be, or use a Docker volume instead. Make sure it is set to _something_ though, so the database will persist across container re/starts.

Currently, this is configured for Phabricator to use the 'root' database user. I tried a setup with a separate SQL user account, but the Phabricator 'bin/storage' doesn't assist with separate user permissions for some reason?! Asinine, and I'll consider that an upstream issue, and therefore not worth my time to fix. If you'd like to submit a Pull Request that solves this, I'll consider it :)

Of course, you can use the MySQL container instead of MariaDB if you'd like.


### The actual Phuntainer!

Before starting Phuntainer, create a file in ```${HOST_STORAGE_PATH}/local.json``` and fill it with at minimum MySQL configurations. And example local.json file is in this repo's [phuntainer/files/local.json](https://github.com/staehle/phuntainer/blob/master/phuntainer/files/local.json)

Create the Phuntainer container:
```
$ docker run -d \
    --name phabricator \
    --network ${PHAB_NETWORK_NAME} \
    --restart=unless-stopped \
    -p 80:80 \
    -p 443:443 \
    -v ${HOST_STORAGE_PATH}/local.json:/phabricator/conf/local/local.json \
    -v ${HOST_STORAGE_PATH}/extensions:/phabricator/src/extensions \
    -v ${HOST_STORAGE_PATH}/repodata:/var/repo \
    staehle/phuntainer:latest
```


### Phuntainer Environment Variable Configuration

`DO_NOT_UPGRADE_ON_BOOT`: If set to any value, will **skip** the upgrading process for Phabricator and dependencies on container start.


## Phabricator Configuration

Hey, you should follow this guide after starting Phuntainer: [Official Phabricator User Documentation](https://secure.phabricator.com/book/phabricator/)

Sometimes, you'll need to run some './bin/config' commands from outside the Web UI. To do this, you can use 'docker exec' to directly manipulate your running Phuntainer. For example:

```
$ docker exec phabricator ./bin/config set <key> <value>
```


## Building the Phuntainer image from scratch

You don't need to do this if you're just pulling the image from Docker Hub

```
cd phuntainer
cat build-cmd-latest | bash -
```

