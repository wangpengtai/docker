ARG CI_REGISTRY_IMAGE="registry.gitlab.com/gitlab-org/build/cng"
ARG FROM_IMAGE="$CI_REGISTRY_IMAGE/git-base"
ARG TAG=2.18.1
ARG GITLAB_EDITION=gitlab-rails-ee
ARG RAILS_VERSION=latest
ARG RUBY_VERSION=latest

FROM ${FROM_IMAGE}:${TAG} as builder

ARG WORKHORSE_VERSION=v5.0.0
ARG BUILD_DIR=/tmp/build

RUN buildDeps=' \
  make' \
  && apt-get update \
  && apt-get install -y --no-install-recommends $buildDeps \
  && mkdir -p ${BUILD_DIR} \
  && cd ${BUILD_DIR} \
  && curl -o workhorse.tar.bz2 https://gitlab.com/gitlab-org/gitlab-workhorse/repository/${WORKHORSE_VERSION}/archive.tar.bz2 \
  && tar -xjf workhorse.tar.bz2 \
  && rm workhorse.tar.bz2 \
  && cd gitlab-workhorse-* \
  && make install \
  && cd \
  && rm -rf ${BUILD_DIR} \
  && apt-get purge -y --auto-remove $buildDeps \
  && rm -rf /var/lib/apt/lists/*

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


FROM ${CI_REGISTRY_IMAGE}/${GITLAB_EDITION}:${RAILS_VERSION} as rails

FROM ${CI_REGISTRY_IMAGE}/gitlab-ruby:${RUBY_VERSION}

ARG DATADIR=/var/opt/gitlab
ARG CONFIG=/srv/gitlab/config
ARG GITLAB_USER=git

# create gitlab user
RUN adduser --disabled-password --gecos 'GitLab' ${GITLAB_USER} && \
  install -d -o ${GITLAB_USER} /var/log/gitlab/ && \
  install -d -o ${GITLAB_USER} ${DATADIR} && \
  install -d -o ${GITLAB_USER} ${CONFIG}

COPY --from=builder /usr/local/bin/gitlab-* /usr/local/bin/

COPY --from=rails --chown=git /srv/gitlab/public/ /srv/gitlab/public/

COPY --from=rails --chown=git /srv/gitlab/doc/ /srv/gitlab/doc/

USER $GITLAB_USER:$GITLAB_USER

COPY scripts/ /scripts/

CMD /scripts/start-workhorse

HEALTHCHECK --interval=30s --timeout=30s --retries=5 \
CMD /scripts/healthcheck
