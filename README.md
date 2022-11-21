# Samba Container

[![License](https://img.shields.io/github/license/realk1ko/samba-container.svg)](https://github.com/realk1ko/samba-container/blob/main/LICENSE)

## About

The container provided here allows you to run Samba in a container-only environment.

## Tags

The following tags are published to the GitHub Container Registry:

- The `:latest` tag is updated every Monday
- The `:dev` tag refers to the image automatically built on the last commit on the `dev` branch. **Please do not use
  this.**

## Usage

### TL;DR

```
docker run \
    -d \
    --name samba \
    -v samba:/etc/samba
    -p 137-138:137-138/udp \
    -p 139:139 \
    -p 445:445 \
    ghcr.io/realk1ko/samba
```

The samba volume should contain the `smb.conf` file. Naturally you will need to add additional mountpoints for the
shares you'd like to configure.

## Why?

Because I need a regularly updated Samba container.
