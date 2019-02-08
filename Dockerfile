ARG ALPINE_VERSION=3.7
FROM alpine:${ALPINE_VERSION}
ARG ALPINE_VERSION=3.7

RUN apk add --no-cache alpine-sdk lua-aports sudo \
  && adduser -G abuild -D builder \
  && echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir -p /var/cache/apk \
  && ln -s /var/cache/apk /etc/apk/cache

USER builder

ENV HOME="/home/builder"
ENV APORTSDIR="${HOME}/aports"
ENV REPODIR="${HOME}/packages"

ENV SRCDIR="/src"
ENV PACKAGER_PRIVKEY="${HOME}/.abuild/builder@alpine-ros-experimental.rsa"

RUN mkdir -p ${APORTSDIR}
WORKDIR ${APORTSDIR}

COPY build-repo.sh /

ENTRYPOINT ["/build-repo.sh"]
