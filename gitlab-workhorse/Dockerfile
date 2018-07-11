ARG FROM_IMAGE=registry.gitlab.com/gitlab-org/build/cng/git-base
ARG TAG=2.17.1
FROM ${FROM_IMAGE}:${TAG} as builder

ENV WORKHORSE_VERSION=5.0.0
ARG BUILD_DIR=/tmp/build

RUN buildDeps=' \
  make' \
  && apt-get update \
  && apt-get install -y --no-install-recommends $buildDeps \
  && mkdir -p ${BUILD_DIR} \
  && cd ${BUILD_DIR} \
  && curl -o workhorse.tar.bz2 https://gitlab.com/gitlab-org/gitlab-workhorse/repository/v${WORKHORSE_VERSION}/archive.tar.bz2 \
  && tar -xjf workhorse.tar.bz2 \
  && rm workhorse.tar.bz2 \
  && cd gitlab-workhorse-* \
  && make install \
  && cd \
  && rm -rf ${BUILD_DIR} \
  && apt-get purge -y --auto-remove $buildDeps \
  && rm -rf /var/lib/apt/lists/*

FROM debian:stretch-slim
ARG DATADIR=/var/opt/gitlab
ARG CONFIG=$DATADIR/config/gitlab
ARG GITLAB_USER=git

COPY --from=builder /usr/local/bin/gitlab-workhorse /usr/local/bin/

COPY scripts/ /srv/bin/

CMD /srv/bin/start-workhorse
