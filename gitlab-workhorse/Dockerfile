ARG FROM_IMAGE=registry.gitlab.com/gitlab-org/build/cng/git-base
ARG TAG=2.17.1
ARG GITLAB_EDITION=gitlab-rails-ee
ARG GITLAB_VERSION=latest

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

FROM registry.gitlab.com/gitlab-org/build/cng/${GITLAB_EDITION}:${GITLAB_VERSION} as rails

FROM debian:stretch-slim

ARG DATADIR=/var/opt/gitlab
ARG CONFIG=$DATADIR/config/gitlab
ARG GITLAB_USER=git

# create gitlab user
RUN adduser --disabled-password --gecos 'GitLab' ${GITLAB_USER}

RUN install -d -o ${GITLAB_USER} /var/log/gitlab/

RUN install -d -o ${GITLAB_USER} ${DATADIR}

RUN install -d -o ${GITLAB_USER} ${CONFIG}

COPY --from=builder /usr/local/bin/gitlab-workhorse /usr/local/bin/

COPY --from=rails /srv/gitlab/app/assets/ /srv/gitlab/app/assets/

COPY --from=rails scripts/ /scripts/

ENV CONFIG_TEMPLATE_DIRECTORY=/etc

ENTRYPOINT ["/scripts/entrypoint.sh"]

CMD /scripts/start-workhorse
