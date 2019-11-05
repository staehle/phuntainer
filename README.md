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

Replace `${HOST_STORAGE_PATH}/sql` with a path to where you want the SQL storage to be, or use a Docker volume instead. Make sure it is set to _something_ though, so the database will persist across container re/starts.

Currently, this is configured for Phabricator to use the `root` database user. I tried a setup with a separate SQL user account, but the Phabricator `bin/storage` application doesn't assist with separate user permissions for some reason?! Asinine, and I'll consider that an upstream issue, and therefore not worth my time to fix. If you'd like to submit a Pull Request that solves this, I'll consider it :)

Of course, you can use the MySQL container instead of MariaDB if you'd like.


### The actual Phuntainer!

#### Volumes

| Host Path | Container Path | Usage |
|---|---|---|
| `${HOST_STORAGE_PATH}/config` | `/config` | Persistent storage for configuration. See 'Configuration Directory' section below. |
| `${HOST_STORAGE_PATH}/repodata` | `/var/repo` | Persistent storage for repositories |

#### Configuration files

Your configuration directory should have this tree layout. If any items are missing, a default/example copy of the file will be copied on container boot which you can then edit.

* `${HOST_STORAGE_PATH}/config/`
  * `local/` -- Subdirectory to hold config data
    * `local.json` -- Local configuration for Phabricator. Recommended to create this file initially, with at minimum MySQL configurations. An example local.json file is in this repo's [phuntainer/files/local.json](https://github.com/staehle/phuntainer/blob/master/phuntainer/files/local.json). **NOTE** the example file has some required settings, such as `diffusion.ssh-user` and `phd.user` set to "ph", reflecting the username value used across many files in this repo.
  * `extensions/` -- If you have Phabricator PHP extensions, put them in this subdirectory.
  * `preamble.php` -- Phabricator Preamble PHP file. This may not apply to your situation. See [this page from Phabricator's documentation](https://secure.phabricator.com/book/phabricator/article/configuring_preamble/)
  * `sshd_config` -- For Git SSHD usage. The default file should be enough for most scenarios, and exposes default SSH port 22. See [this page from Phabricator's documentation](https://secure.phabricator.com/book/phabricator/article/diffusion_hosting/)
  * `ssh-secret/` -- Also for SSHD, contains permission-sensitive items. This is the only directory owned by `root`.



#### Environment Variables

`PUID`: Set this variable to the host Unix user ID. This will be set as the user ID for the `ph` user, which runs PHD and used for SSH, as well as file permissions on the host.

`GUID`: If your group ID is different, set this variable. Otherwise PUID will be assumed.

`DO_NOT_UPGRADE_ON_BOOT`: If set to any value, will **skip** the upgrading process for Phabricator and dependencies on container start.

#### Start the Phuntainer!

```
$ docker run -d \
    --name phabricator \
    --network ${PHAB_NETWORK_NAME} \
    --restart=unless-stopped \
    -p 80:80 \
    -p 443:443 \
    -p 22:22 \
    -e PUID=1000 \
    -e GUID=1000 \
    -v ${HOST_STORAGE_PATH}/config:/config \
    -v ${HOST_STORAGE_PATH}/repodata:/var/repo \
    staehle/phuntainer:latest
```

## Phabricator Configuration

Hey, you should follow this guide after starting Phuntainer: [Official Phabricator User Documentation](https://secure.phabricator.com/book/phabricator/)

Sometimes, you'll need to run some './bin/config' commands from outside the Web UI. To do this, you can use 'docker exec' to directly manipulate your running Phuntainer. For example, if you used 'phabricator' for the container name above:

```
$ docker exec phabricator ./bin/config set <key> <value>
```


## Building the Phuntainer image from scratch

You don't need to do this if you're just pulling the image from Docker Hub

```
cd phuntainer
cat build-cmd-latest | bash -
```

