# Samba Container

[![License](https://img.shields.io/github/license/realk1ko/samba-container.svg)](https://github.com/realk1ko/samba-container/blob/main/LICENSE)

## About

The container provided here allows you to run Samba in a container-only environment.

## Tags

The following tags are used for the images:

- `:latest`: This is the tag you should be using. It is updated every Monday automatically. Additionally, each release
  has a date tag (e. g. `:2022-11-22`).
- `:edge`: Latest build of the image on the latest commit on the `dev` branch. Each image tagged with this is also
  tagged with the SHA commit reference it was built on (e. g. `:sha-bb8c5c4`).

## Usage

### Setup

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

### About Permissions and Advanced Features

This container primarily serves me and my use case. I was not satisfied with other solutions, they're overly
complicated, get rarely updated or just don't work properly.

As a result, a "permission-less" concept good enough for a home server is used here:

- All files and directories in all shares belong to the user `nobody` and the group `nobody` per default.
- Only users that are able to login via Samba can access those files and directories.
- Other users simply can't access the files, not even on the host (if properly configured), with the sole exception
  being the root or administrative users.

The [default configuration](https://github.com/realk1ko/samba-container/blob/main/container/usr/local/etc/samba-container/smb.conf.template)
of Samba in the container reflects this. On startup his configuration is copied to the `/etc/samba` directory only if
no `smb.conf` exists there.

### Adding Users

On each startup, the container will check the local credentials database of Samba (located in `/var/lib/samba/private`)
and re-create UNIX users corresponding to the Samba users, if they do not already exist. This is useful for primarily
three reasons:

- Users do not have to be defined via parameters.
- Passwords do not have to be defined via parameters or other insecure means.
- You don't need to make `/etc/passwd`, `/etc/shadow` and `/etc/group` persistent.

However, the UIDs/GIDs of the users are **not ensured to be consistent** between "re-creations" of a user, making this a
bad option if you're trying to make the files and directories accessible for users from the host or even the users
themselves via other file sharing applications.

The user re-creation **only works** if you're using `tdbsam` as password database backend for Samba. This is
the [default behaviour](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html#idm7607) in most - if not
all - distributions and this container.

To add a new user, simply login to the container using:

```
docker exec -it name-of-your-container /bin/bash
```

Then add a new UNIX user and define a password (used only for Samba):

```
adduser -M -s /sbin/nologin your-username
smbpasswd -a your-username
```

This way the user will only be able to login to Samba, not the container itself via other means.

### Adding Shares

Make sure the share directory has the following permissions:

- Owner: `nobody`
- Group: `nobody`
- Permissions: `rwxrwx---` (770) for directories and `rw-rw----` (660) for files

Then simply modify both the volume mounts and the `smb.conf` to your needs. The default configuration contains two
inactive sample shares: A public and a private one. Refer to the following resources for detailed information on
configuring shares and Samba itself:

- https://github.com/realk1ko/samba-container/blob/main/container/usr/local/etc/samba-container/smb.conf.template
- https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html
- https://wiki.archlinux.org/title/samba
