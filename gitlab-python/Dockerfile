FROM debian:stretch-slim

ARG BUILD_DIR=/tmp/build
ARG PYTHON_VERSION="3.4.9"
ARG DOCUTILS_VERSION="0.11"

RUN buildDeps=' \
  build-essential \
  ca-certificates \
  curl \
  file \
  gcc \
  libssl1.0-dev \
  make \
  zlib1g-dev' && \
  apt-get update && \
  apt-get install -y --no-install-recommends $buildDeps && \
  mkdir ${BUILD_DIR} && \
  curl -fsSL https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
  | tar -xz -C ${BUILD_DIR}  && \
  cd ${BUILD_DIR}/Python-${PYTHON_VERSION} && \
  ./configure --enable-shared --with-readline=editline --with-dbmliborder= && make && \
  make install && \
  /usr/local/bin/pip3 install --compile docutils==${DOCUTILS_VERSION} && \
  rm -rf /usr/local/lib/python/3.4/lib-dynload/dbm.* && \
  rm -rf /usr/local/lib/python/3.4/lib-dynload/_sqlite3.* && \
  rm -rf /usr/local/lib/python/3.4/test && \
  find /usr/local/lib/python3.4 -name '__pycache__' -type d -print -exec rm -r {} + && \
  apt-get purge -y $buildDeps && \
  rm -rf /var/lib/apt/list/* && \
  rm -rf ${BUILD_DIR}

CMD [ "python" ]
