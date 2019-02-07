ARG ALPINE_VERSION=3.7
FROM alpine:${ALPINE_VERSION}
ARG ALPINE_VERSION=3.7

RUN apk add --no-cache alpine-sdk lua-aports sudo \
  && adduser -G abuild -D builder \
  && echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN echo $'-----BEGIN PUBLIC KEY-----\n\
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnSO+a+rIaTorOowj3c8e\n\
5St89puiGJ54QmOW9faDsTcIWhycl4bM5lftp8IdcpKadcnaihwLtMLeaHNJvMIP\n\
XrgEEoaPzEuvLf6kF4IN8HJoFGDhmuW4lTuJNfsOIDWtLBH0EN+3lPuCPmNkULeo\n\
iS3Sdjz10eB26TYiM9pbMQnm7zPnDSYSLm9aCy+gumcoyCt1K1OY3A9E3EayYdk1\n\
9nk9IQKA3vgdPGCEh+kjAjnmVxwV72rDdEwie0RkIyJ/al3onRLAfN4+FGkX2CFb\n\
a17OJ4wWWaPvOq8PshcTZ2P3Me8kTCWr/fczjzq+8hB0MNEqfuENoSyZhmCypEuy\n\
ewIDAQAB\n\
-----END PUBLIC KEY-----' > /etc/apk/keys/builder@alpine-ros-experimental.rsa.pub

RUN mkdir -p /var/cache/apk \
  && ln -s /var/cache/apk /etc/apk/cache

USER builder

ENV HOME="/home/builder"
ENV PACKAGER_PRIVKEY="${HOME}/.abuild/builder@alpine-ros-experimental.rsa"
ENV APORTSDIR="${HOME}/aports"
ENV REPODIR="${HOME}/packages"
ENV SRCDIR="/src"

COPY build-repo.sh /

RUN mkdir -p ${APORTSDIR}
WORKDIR ${APORTSDIR}

ENTRYPOINT ["/build-repo.sh"]
