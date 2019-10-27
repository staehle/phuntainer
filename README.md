# phuntainer
A Fun Container for Phabricator (Docker)

## Using phuntainer

This is assuming a manual setup. The following could be converted to a Docker Compose fairly easy -- some assembly required there.

### Docker Network

Create a Docker network:
```
$ docker network create network-phabricator
```

### Storage -- Using MariaDB as a MySQL server

Create a MariaDB container:
```
$ docker run -d \
    --name mariadb-phabricator \
    --network network-phabricator \
    --restart=unless-stopped \
    -e MYSQL_ROOT_PASSWORD=rootsecretpassword \
    -v /host/path/to/mariadbstorage:/var/lib/mysql \
    mariadb:10.4
```

Replace '/host/path/to/mariadbstorage' with a path to where you want the MariaDB storage to be, or use a Docker volume instead. Make sure it is set to _something_ though, so the database will persist across container re/starts.

Currently, this is configured for Phabricator to use the 'root' database user. I tried a setup with a separate SQL user account, but the Phabricator 'bin/storage' doesn't assist with separate user permissions for some reason?! Asinine, so isn't worth my time to fix. If you'd like to submit a Pull Request that solves this, go for it :)


### The actual Phuntainer!

Create the Phuntainer container:
```
$ docker run -d \
    --name phabricator \
    --network network-phabricator \
    --restart=unless-stopped \
    -p 80:80 -p 443:443 \
    -e UPGRADE_ON_BOOT=true \
    -v /host/path/to/local.json:/phab/phabricator/conf/local/local.json \
    phuntainer:latest
```

Replace '/host/path/to/local.json' with a path to where you have an existing Phabricator local.json
An example local.json file:
```
{
    "phabricator.base-uri": "localhost",
    "mysql.host": "mariadb-phabricator",
    "mysql.port": "3306",
    "mysql.user": "root",
    "mysql.pass": "rootsecretpassword",
    "storage.mysql-engine.max-size": "9000000",
    "phpmailer.mailer": "smtp",
    "phpmailer.smtp-host": "localhost",
    "phpmailer.smtp-port": 25,
    "phpmailer.smtp-user": "phabricator",
    "phpmailer.smtp-password": "",
    "phpmailer.smtp-protocol": "",
    "metamta.mail-adapter": "PhabricatorMailImplementationPHPMailerAdapter",
    "":""
}
```

### Environment Variable Configuration

`UPGRADE_ON_BOOT`: Set to "true" or "false". Will upgrade Phabricator and dependencies on each container start if set.


## Creating Phuntainer from scratch
```
cd phuntainer
docker build -t phuntainer:latest .
```

## Phabricator Configuration

Hey, you should follow this guide after starting Phuntainer: [https://secure.phabricator.com/book/phabricator/]

Sometimes, you'll need to run some './bin/config' commands from outside the Web UI. To do this, you can use 'docker exec' to directly manipulate your running Phuntainer:

```
$ docker exec phabricator ./bin/auth lock
```

