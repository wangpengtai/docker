#!/bin/sh
# install-cfssl.sh
# 
# Download and install CFSSL from https://pkg.cfssl.org/
CFSSL_VERSION=${CFSSL_VERSION:-1.2}
CFSSL_PKG_URL="https://pkg.cfssl.org/R${CFSSL_VERSION}"
CFSSL_PLATFORM=${CFSSL_PLATFORM:-linux-amd64}

for item in cfssl cfssljson ; do
  wget -O /bin/${item} ${CFSSL_PKG_URL}/${item}_${CFSSL_PLATFORM}
  chmod +x /bin/${item}
done

