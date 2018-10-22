ARG CI_REGISTRY_IMAGE="registry.gitlab.com/gitlab-org/build/cng"
ARG FROM_IMAGE="$CI_REGISTRY_IMAGE/git-base"
ARG TAG=2.17.1
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

FROM ${CI_REGISTRY_IMAGE}/${GITLAB_EDITION}:${RAILS_VERSION} as rails

# charts/gitlab#689
# Strip down /srv/gitlab/vendor/bundle/ruby/* to
#   /srv/gitlab/vendor/bundle/ruby/?.?.?/gems/sidekiq-?.?.?/web/assets
RUN \
  KEEP=$(find /srv/gitlab/vendor/bundle/ruby -type d -name assets | grep 'sidekiq-.*\/web\/assets') \
  && mv $KEEP /tmp/sidekiq_assets \
  && rm -rf /srv/gitlab/vendor/bundle/ruby/ \
  && mkdir -p $KEEP \
  && mv /tmp/sidekiq_assets/* $KEEP/

FROM ${CI_REGISTRY_IMAGE}/gitlab-ruby:${RUBY_VERSION}

ARG DATADIR=/var/opt/gitlab
ARG CONFIG=$DATADIR/config/gitlab
ARG GITLAB_USER=git

# create gitlab user
RUN adduser --disabled-password --gecos 'GitLab' ${GITLAB_USER} && \
  install -d -o ${GITLAB_USER} /var/log/gitlab/ && \
  install -d -o ${GITLAB_USER} ${DATADIR} && \
  install -d -o ${GITLAB_USER} ${CONFIG}

COPY --from=builder /usr/local/bin/gitlab-* /usr/local/bin/

COPY --from=rails --chown=git /srv/gitlab/public/ /srv/gitlab/public/

COPY --from=rails --chown=git /srv/gitlab/doc/ /srv/gitlab/doc/

COPY --from=rails --chown=git /srv/gitlab/vendor/bundle/ruby /srv/gitlab/vendor/bundle/ruby

USER $GITLAB_USER:$GITLAB_USER

COPY scripts/ /scripts/

CMD /scripts/start-workhorse

HEALTHCHECK --interval=30s --timeout=30s --retries=5 \
CMD /scripts/healthcheck
