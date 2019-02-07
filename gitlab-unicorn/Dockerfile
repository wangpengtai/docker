ARG CI_REGISTRY_IMAGE="registry.gitlab.com/gitlab-org/build/cng"
ARG PYTHON_VERSION="test-upgrade-python"
ARG TAG=latest
ARG FROM_IMAGE="$CI_REGISTRY_IMAGE/gitlab-rails-ee"
ARG GITLAB_USER=git

FROM ${CI_REGISTRY_IMAGE}/gitlab-python:${PYTHON_VERSION} as python

ARG CI_REGISTRY_IMAGE="registry.gitlab.com/gitlab-org/build/cng"


FROM ${FROM_IMAGE}:${TAG}

ARG DATADIR=/var/opt/gitlab
ARG CONFIG=/srv/gitlab/config

COPY --from=python /usr/local/bin /usr/local/bin/
COPY --from=python /usr/local/lib /usr/local/lib/
RUN ldconfig

RUN sed -i 's/python2/python3/' /srv/gitlab/vendor/bundle/ruby/2.4.0/gems/gitlab-markup-1.6.5/lib/github/markups.rb
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
