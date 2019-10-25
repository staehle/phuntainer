# phuntainer
A Fun Container for Phabricator (Docker)

## Using phuntainer

Create a Docker network:
```
$ docker network create network-phabricator
```

Create a MariaDB container:
```
$ docker run -d \
    --name mariadb-phabricator \
    --network network-phabricator \
    --restart=unless-stopped \
    -e MYSQL_USER=phabdbuser \
    -e MYSQL_PASSWORD=phabdbpass \
    -e MYSQL_RANDOM_ROOT_PASSWORD=yes \
    -v /host/path/to/mariadbstorage:/var/lib/mysql \
    mariadb:10.4
```

Replace '/host/path/to/mariadbstorage' with a path to where you want the MariaDB storage to be.

Create the Phuntainer container:
```
$ docker run -d \
    --name phabricator \
    --network network-phabricator \
    --restart=unless-stopped \
    -p 80:80 -p 443:443 \
    -e UPGRADE_ON_BOOT=true \
    -v /host/path/to/local.json:/config/local.json \
    phuntainer:latest
```

Replace '/host/path/to/local.json' with a path to where you have either an existing local.json, or where you want a default one to be copied to.

### Environment Variable Configuration

`UPGRADE_ON_BOOT`: Set to "true" or "false". Will upgrade Phabricator and dependencies on each container start if set.

`PREAMBLE_SCRIPT`: PHP script to inject into site preamble



## Creating from scratch
```
cd phuntainer
docker build -t phuntainer:latest .
```