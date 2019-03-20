ARG CI_REGISTRY_IMAGE="registry.gitlab.com/gitlab-org/build/cng"
ARG TAG=latest
ARG FROM_IMAGE="$CI_REGISTRY_IMAGE/gitlab-rails-ee"

FROM ${FROM_IMAGE}:${TAG}

ARG S3CMD_VERSION="2.0.1"
ARG GSUTIL_VERSION="4.36"

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
  ca-certificates \
  openssl \
  tar \
  python python-pip \
  python-setuptools python-crcmod \
  && pip install --upgrade s3cmd==${S3CMD_VERSION} gsutil==${GSUTIL_VERSION} \
  && rm -rf /var/lib/apt/lists/*

ARG GITLAB_USER=git

COPY scripts/ /scripts

RUN cp scripts/bin/* /usr/local/bin && cp scripts/lib/* /usr/lib/ruby/vendor_ruby

USER $GITLAB_USER:$GITLAB_USER

ENTRYPOINT ["/scripts/bin/entrypoint.sh"]
