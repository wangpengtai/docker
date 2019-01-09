ARG TAG=latest
ARG CI_REGISTRY_IMAGE="registry.gitlab.com/gitlab-org/build/cng"
ARG FROM_IMAGE="$CI_REGISTRY_IMAGE/gitlab-rails-ee"
FROM ${FROM_IMAGE}:${TAG}

ARG BUILD_DIR=/tmp/build
ARG DATADIR=/var/opt/gitlab
ARG CONFIG=/srv/gitlab/config
ARG GITLAB_USER=git

COPY scripts/ /scripts
COPY unicorn.rb ${CONFIG}/unicorn.rb

RUN cd /srv/gitlab && \
    mkdir -p public/uploads && chown ${GITLAB_USER}:0 public/uploads && \
    chmod 0770 public/uploads

ENV GITALY_FEATURE_DEFAULT_ON=1

CMD /scripts/process-wrapper

HEALTHCHECK --interval=30s --timeout=30s --retries=5 \
CMD /scripts/healthcheck
