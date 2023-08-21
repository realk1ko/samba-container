ARG BASE_IMAGE

FROM ${BASE_IMAGE}

ARG SAMBA_VERSION

LABEL org.opencontainers.image.title Samba
LABEL org.opencontainers.image.description A simple Samba container with support for mDNS
LABEL org.opencontainers.image.licenses MIT
LABEL org.opencontainers.image.url https://github.com/realk1ko/samba-container
LABEL maintainer realk1ko <32820057+realk1ko@users.noreply.github.com>

ADD ./container /

ADD ./LICENSE /

RUN set -euo pipefail && \
    dnf install -y supervisor samba-${SAMBA_VERSION} python3 python3-pip && \
    dnf clean all && \
    pip install -r /usr/local/etc/samba-container/requirements.txt && \
    dnf autoremove -y python3-pip && \
    chmod 755 /usr/local/bin/*

CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]
