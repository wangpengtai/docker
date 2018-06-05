ARG TAG=latest
ARG FROM_IMAGE=registry.gitlab.com/gitlab-org/build/cng/gitlab-rails-ee
FROM ${FROM_IMAGE}:${TAG}

ARG BUILD_DIR=/tmp/build
ARG DATADIR=/var/opt/gitlab
ARG CONFIG=$DATADIR/config/gitlab
ARG GITLAB_USER=git

ARG GO_VERSION=1.9.6
RUN mkdir -p ${BUILD_DIR} \
  && cd ${BUILD_DIR} \
  && curl -so golang.tar.gz "https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz" \
  && tar -xf golang.tar.gz \
  && mv ${BUILD_DIR}/go /usr/local/go \
  && rm golang.tar.gz \
  && rm -rf /var/lib/apt/lists/* \
  && ln -sf /usr/local/go/bin/go /usr/local/go/bin/gofmt /usr/local/go/bin/godoc /usr/local/bin/

RUN buildDeps=' \
  cmake \
  g++ \
  gcc \
  make' \
  && apt-get update \
  && apt-get install -y --no-install-recommends $buildDeps \
  && mkdir -p ${BUILD_DIR} \
  && cd ${BUILD_DIR} \
  && WORKHORSE_VERSION=$(cat /home/git/gitlab/GITLAB_WORKHORSE_VERSION) \
  && curl -o workhorse.tar.bz2 https://gitlab.com/gitlab-org/gitlab-workhorse/repository/v${WORKHORSE_VERSION}/archive.tar.bz2 \
  && tar -xjf workhorse.tar.bz2 \
  && rm workhorse.tar.bz2 \
  && cd gitlab-workhorse-* \
  && make install \
  && cd \
  && rm -rf ${BUILD_DIR} \
  && apt-get purge -y --auto-remove $buildDeps \
  && rm -rf /var/lib/apt/lists/*

USER $GITLAB_USER:$GITLAB_USER

COPY scripts/ /scripts
COPY unicorn.rb ${CONFIG}/unicorn.rb

RUN cd /home/${GITLAB_USER}/gitlab && \
    ln -s ${CONFIG}/unicorn.rb config/unicorn.rb

ENV GITALY_FEATURE_DEFAULT_ON=1

CMD /scripts/process-wrapper

HEALTHCHECK --interval=30s --timeout=30s --retries=5 \
CMD /scripts/healthcheck
