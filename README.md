# Samba Container

[![License](https://img.shields.io/github/license/realk1ko/samba-container.svg)](https://github.com/realk1ko/samba-container/blob/main/LICENSE)

## About

The container provided here allows you to run Samba with mDNS in a container-only environment.

## Tags

The following tags are used for the images:

- `:latest`: This is the tag you should be using. It is updated every Monday automatically. Additionally, each release
  has a date tag (e. g. `:2022-11-22`).
- `:edge`: Latest build of the image on the latest commit on the `dev` branch. Each image tagged with this is also
  tagged with the SHA commit reference it was built on (e. g. `:sha-bb8c5c4`).

## Usage

### Setup

If you plan on using the container with mDNS support (e. g. to use it with Time Machine) you need to setup the container
with host networking:

```
docker run \
    -d \
    --name samba \
    -v samba-config:/etc/samba \
    -v samba-private:/var/lib/samba/private \
    --net host \
    ghcr.io/realk1ko/samba:latest
```

Alternatively you can run the container with normal port forwards:

```
docker run \
    -d \
    --name samba \
    -v samba-config:/etc/samba \
    -v samba-private:/var/lib/samba/private \
    -p 137-138:137-138/udp \
    -p 139:139 \
    -p 445:445 \
    ghcr.io/realk1ko/samba:latest
```

The `samba-config` volume maps to the Samba configuration directory which contains all relevant files for
customizing it.

The `samba-private` volume maps to the Samba directory for the password credentials database. This is to make
the users' credentials persistent.

The [default configuration](https://github.com/realk1ko/samba-container/blob/main/container/usr/local/etc/samba-container/smb.conf.template)
of Samba in the container is copied to the `/etc/samba` directory if no `smb.conf` exists there.

### User Management

#### About Permissions

A "permission-less" concept good enough for a home server is used for Samba with this container:

- All files and directories in all shares belong to the user `nobody` and the group `nobody` per default.
- Only users that are able to login via Samba can access those files and directories.
- Other users simply can't access the files, not even on the host (if properly configured), with the sole exception
  being the root and administrative users.

On each startup, the container will check the local credentials database of Samba (located in `/var/lib/samba/private`)
and re-create UNIX users corresponding to the Samba users, if they do not already exist. This is useful for primarily
three reasons:

- Users do not have to be defined via parameters.
- Passwords do not have to be defined via parameters or other insecure means.
- You don't need to make `/etc/passwd`, `/etc/shadow` and `/etc/group` persistent.

However, the UIDs/GIDs of the users are **not ensured to be consistent** between "re-creations" of a user, making this
container a **bad option** if you're trying to make the files and directories accessible for users from the host or
other users via different file sharing applications (e. g. NFS).

The user re-creation **only works** if you're using `tdbsam` as password database backend for Samba. This is
the [default behaviour](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html#idm7607) in most - if not
all - distributions and this container.

#### Adding Users

To add a new user, simply login to the running container using:

```
docker exec -it name-of-your-container /bin/bash
```

Then add a new UNIX user, add it's corresponding Samba user and define a password interactively (used only for Samba):

```
adduser -M -s /sbin/nologin your-username
smbpasswd -a your-username
```

This way the user will only be able to login to Samba, not the container itself via other means.

### Share Management

Make sure the directories and files you would like to share have the following permissions:

- Owner: `nobody`
- Group: `nobody`
- Permissions: `rwxrwx---` (770) for directories and `rw-rw----` (660) for files

Then simply modify both the volume mounts and the `smb.conf` to your needs. The default configuration contains a few
sample shares to get you started. Refer to the following resources for detailed information on configuring shares:

- https://github.com/realk1ko/samba-container/blob/main/container/usr/local/etc/samba-container/smb.conf.template
- https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html
- https://wiki.archlinux.org/title/samba

### Configuring mDNS

This container comes with mDNS support enabled per default (without Avahi). If you're using host networking for your
container, the Samba server will be advertised to all mDNS-compatible devices on your network. This allows you to find
your server via local network discovery on Apple devices and most Linux distributions.

Configuration for mDNS is done via the `smb.conf` as with normal Samba and Avahi setups.

**Please note: mDNS is only supported for IPv4 currently.**

#### Disabling mDNS

If you wish to disable mDNS support, simply set the following setting in your `smb.conf`:

```
multicast dns register = no
```

You can then also change the container to use normal port forwards instead of host networking for added security.

#### Customize Hostname

The container will use the container's hostname as default for the mDNS advertisement. If you wish to change the
hostname of the service, change the hostname of the container by adding this line to your container setup:

```
--hostname My-Samba-Server
```

The `smb.conf` still may have an effect on the used hostname for mDNS. The rules to get a hostname for Samba with Avahi
apply here aswell. Refer to the section on mDNS names in the `smb.conf`
documentation [here](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html#idm6797) for more info.

#### Customizing Service Name

You can configure the service name of Samba by adding the following setting in the `smb.conf`:

```
server string = My Samba Server
```

The service name is the visible text shown in the network discovery on client devices. This setting also changes
the [server description](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html#idm9421).

Setting the service name is not possible with normal Samba and Avahi service. **This exclusively works with this
container.**

#### Advertise Shares for Time Machine

If you wish to advertise one of your shares for Time Machine backups on MacOS, simply add the following setting to the
share section.

```
fruit:time machine = yes
```

This setting can also be added to the `[global]` section, in which case all shares will be advertised for Time Machine
unless otherwise configured within the share section.

#### Interfaces for mDNS

If you have a system with multiple network interfaces you may wish to configure the interfaces on which Samba will allow
connections on and advertise it's service. Per default the container will allow logins to Samba from all interfaces and
as such will also advertise the service on all interfaces.

You can configure one or more interfaces for which Samba will allow connections and advertise it's service by adding the
following lines to your `smb.conf`:

```
bind interfaces only = yes
interfaces = eth0 eth1
```

In this example Samba will only allow connections coming from the interfaces `eth0` and `eth1` and also advertise it's
Samba service on it.
