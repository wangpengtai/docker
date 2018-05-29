FROM alpine:3.6

ARG BUILD_DIR=/tmp/build
ARG RUBY_MAJOR_VERSION=2.3
ARG RUBY_MINOR_VERSION=2.3.5
ARG RUBYGEMS_VERSION=2.6.13
ARG BUNDLER_VERSION=1.15.4

# Alpine ships C.UTF-8 by default, but doesn't set the ENV.
# ref: https://bugs.alpinelinux.org/issues/7374
ENV LANG=C.UTF-8

# install runtime deps
RUN apk add --no-cache \
        bzip2 \
        ca-certificates \
        libffi-dev \
        libressl-dev=2.5.5-r1 \
        procps \
        yaml-dev \
        zlib-dev \
        ncurses \
        libedit \
        curl \
        git \
        gnupg \
        bash

# install build deps
RUN apk add --no-cache --virtual .build-deps \
        bison \
        bzip2-dev \
        coreutils \
        gcc \
        glib-dev \
        libc-dev \
        libffi-dev \
        libxml2-dev \
        libxslt-dev \
        libedit-dev \
        linux-headers \
        make \
        ncurses-dev \
        procps \
        tar \
        xz && \
        mkdir -p ${BUILD_DIR}

# skip installing gem documentation
RUN mkdir -p /usr/etc && \
    { echo 'install: --no-document';  echo 'update: --no-document'; } >> /usr/etc/gemrc

# Install Ruby from source
# Fix configure script for alpine: https://github.com/gliderlabs/docker-alpine/issues/261
RUN cd ${BUILD_DIR} && \
    curl -so ruby.tar.bz2 https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR_VERSION}/ruby-${RUBY_MINOR_VERSION}.tar.bz2 && \
    tar -xjf ruby.tar.bz2 && \
    rm ruby.tar.bz2 && \
    cd ruby-${RUBY_MINOR_VERSION} && \
    ac_cv_func_isnan=yes ac_cv_func_isinf=yes ./configure --prefix=/usr --with-libedit --with-out-ext=dbm --enable-shared --disable-install-doc --without-gmp --without-gdbm --without-tk --disable-dtrace && \
    make -j "$(nproc)" && \
    make -j "$(nproc)" install && \
    cd && \
    apk del .build-deps && \
    rm -rf ${BUILD_DIR} /usr/lib/libruby-static.a && \
    gem update --system "$RUBYGEMS_VERSION" && \
    gem install bundler --version "$BUNDLER_VERSION" --force

# Add scripts
COPY scripts/ /scripts

ENV CONFIG_TEMPLATE_DIRECTORY=/etc

ENTRYPOINT ["/scripts/entrypoint.sh"]

CMD [ "irb" ]
