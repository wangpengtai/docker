#!/bin/bash

## Used to build and install postgresql from source
## Only works on alpine with with a C compiler

pkgver=9.6.8
source_url=https://ftp.postgresql.org/pub/source/v$pkgver/postgresql-$pkgver.tar.bz2

apk add --no-cache libedit-dev zlib-dev libxml2-dev util-linux-dev openldap-dev
wget $source_url && tar -xjf postgresql-$pkgver.tar.bz2 && cd postgresql-$pkgver

./configure --prefix=/usr --with-ldap --with-libedit-preferred --with-libxml --with-openssl --with-uuid=e2fs --disable-rpath && \
  make && make install
