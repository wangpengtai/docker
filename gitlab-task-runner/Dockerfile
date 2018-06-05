ARG TAG=latest
ARG FROM_IMAGE=registry.gitlab.com/gitlab-org/build/cng/gitlab-rails-ee
FROM ${FROM_IMAGE}:${TAG}

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
  postgresql \
  ca-certificates \
  openssl \
  tar \
  python-pip \
  && pip install setuptools \
  && pip install --upgrade s3cmd==2.0.1 \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get purge -y --auto-remove python-pip

ARG GITLAB_USER=git

COPY scripts/ /scripts
RUN cp /scripts/gitlab-rake /scripts/registry-restore /scripts/backup-utility /usr/local/bin

USER $GITLAB_USER:$GITLAB_USER

ENTRYPOINT ["/scripts/entrypoint.sh"]
