ARG CI_REGISTRY_IMAGE="registry.gitlab.com/gitlab-org/build/cng"
ARG PYTHON_VERSION="3.4.9"
ARG TAG=latest
ARG FROM_IMAGE="$CI_REGISTRY_IMAGE/gitlab-rails-ee"

FROM ${CI_REGISTRY_IMAGE}/gitlab-python:${PYTHON_VERSION} as python

FROM ${FROM_IMAGE}:${TAG}

ARG DATADIR=/var/opt/gitlab
ARG CONFIG=/srv/gitlab/config

COPY --from=python /usr/local/bin /usr/local/bin/
COPY --from=python /usr/local/lib /usr/local/lib/
RUN ldconfig

RUN cd /srv/gitlab && sed -i 's/python2/python3/' "$(bundle show gitlab-markup)/lib/github/markups.rb"
# END python install

ARG GITLAB_USER=git

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
