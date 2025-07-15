ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION}
ARG ALPINE_VERSION

RUN sed -i 's|https://\(dl-cdn.alpinelinux.org/\)|http://\1|' /etc/apk/repositories \
  && echo $'-----BEGIN PUBLIC KEY-----\n\
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnSO+a+rIaTorOowj3c8e\n\
5St89puiGJ54QmOW9faDsTcIWhycl4bM5lftp8IdcpKadcnaihwLtMLeaHNJvMIP\n\
XrgEEoaPzEuvLf6kF4IN8HJoFGDhmuW4lTuJNfsOIDWtLBH0EN+3lPuCPmNkULeo\n\
iS3Sdjz10eB26TYiM9pbMQnm7zPnDSYSLm9aCy+gumcoyCt1K1OY3A9E3EayYdk1\n\
9nk9IQKA3vgdPGCEh+kjAjnmVxwV72rDdEwie0RkIyJ/al3onRLAfN4+FGkX2CFb\n\
a17OJ4wWWaPvOq8PshcTZ2P3Me8kTCWr/fczjzq+8hB0MNEqfuENoSyZhmCypEuy\n\
ewIDAQAB\n\
-----END PUBLIC KEY-----' > /etc/apk/keys/builder@alpine-ros-experimental.rsa.pub

RUN apk add --no-cache \
    alpine-sdk \
    ccache \
    git \
    grep \
    lua-aports \
    sudo \
    # Temporary fix missing deps
    # - python_orocos_kdl lack dependency to python-dev
    $([ "$(echo -e "3.16\n${ALPINE_VERSION}" | sort -V | head -n1)" != "3.16" ] && echo python2-dev) \
    python3-dev \
    # - some packages including roslint have implicit dependency to bash
    bash \
  && adduser -G abuild -D builder \
  && echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

VOLUME /cache

COPY scripts/gcc-with-retry/gcc /usr/lib/gcc-with-retry/gcc
RUN ln -s /usr/lib/gcc-with-retry/gcc /usr/lib/gcc-with-retry/g++

ENV CC=/usr/lib/gcc-with-retry/gcc \
  CXX=/usr/lib/gcc-with-retry/g++ \
  CCACHE_DIR=/cache/ccache \
  CCACHE_DEPEND=true

RUN ln -s /cache/apk /etc/apk/cache

# Workaround for rospack on fakeroot
RUN mkdir -p /root/.ros \
  && chmod a+x /root \
  && chmod a+rwx /root/.ros

USER builder

RUN git config --global init.defaultBranch unused \
  && for p in statusAheadBehind statusHints statusUoption detachedHead; do \
      git config --global advice.${p} false; \
    done

ENV HOME="/home/builder"
ENV APORTSDIR="${HOME}/aports" \
  REPODIR="${HOME}/packages" \
  SRCDIR="/src" \
  PACKAGER_PRIVKEY="${HOME}/.abuild/builder@alpine-ros-experimental.rsa"

RUN mkdir -p ${APORTSDIR}
WORKDIR ${APORTSDIR}

COPY update-checksum.sh build-repo.sh /
COPY v${ALPINE_VERSION} ${SRCDIR}/v${ALPINE_VERSION}

ENTRYPOINT ["/build-repo.sh"]
