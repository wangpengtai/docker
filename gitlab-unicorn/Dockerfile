ARG TAG=latest
ARG CI_REGISTRY_IMAGE="registry.gitlab.com/gitlab-org/build/cng"
ARG FROM_IMAGE="$CI_REGISTRY_IMAGE/gitlab-rails-ee"
FROM ${FROM_IMAGE}:${TAG}

ARG PYTHON_VERSION="3.4.9"
ARG DOCUTILS_VERSION="0.11"
ARG BUILD_DIR=/tmp/build
ARG DATADIR=/var/opt/gitlab
ARG CONFIG=/srv/gitlab/config
ARG GITLAB_USER=git

# Start python install
RUN apt-get update && apt-get install -y make gcc && \
 mkdir ${BUILD_DIR} && \
 curl -fsSL https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
  | tar -xz -C ${BUILD_DIR} && cd ${BUILD_DIR}/Python-${PYTHON_VERSION} && \
./configure --enable-shared --with-readline=editline --with-dbmliborder= && make && \
  make install && \
  ldconfig && \
  /usr/local/bin/pip3 install --compile docutils==${DOCUTILS_VERSION} && \
  rm -rf /usr/local/lib/python/3.4/lib-dynload/dbm.* && \
  rm -rf /usr/local/lib/python/3.4/lib-dynload/_sqlite3.* && \
  rm -rf /usr/local/lib/python/3.4/test && \
  find /usr/local/lib/python3.4 -name '__pycache__' -type d -print -exec rm -r {} + && \
  apt-get purge -y make gcc && \
  rm -rf /var/lib/apt/list/* && \
  rm -rf ${BUILD_DIR}

RUN sed -i 's/python2/python3/' /srv/gitlab/vendor/bundle/ruby/2.4.0/gems/github-markup-1.7.0/lib/github/markups.rb
# END python install

USER $GITLAB_USER:$GITLAB_USER

COPY scripts/ /scripts
COPY unicorn.rb ${CONFIG}/unicorn.rb

RUN cd /srv/gitlab && \
    mkdir -p public/uploads && chown ${GITLAB_USER}:${GITLAB_USER} public/uploads && \
    chmod 0700 public/uploads

ENV GITALY_FEATURE_DEFAULT_ON=1

CMD /scripts/process-wrapper

HEALTHCHECK --interval=30s --timeout=30s --retries=5 \
CMD /scripts/healthcheck
