ARG TAG=latest
ARG FROM_IMAGE=registry.gitlab.com/gitlab-org/build/cng/gitlab-rails-ee
FROM ${FROM_IMAGE}:${TAG}

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
  ca-certificates \
  openssl \
  tar \
  python python-pip \
  && pip install setuptools \
  && pip install --upgrade s3cmd==2.0.1 \
  && rm -rf /var/lib/apt/lists/*

ARG GITLAB_USER=git

COPY scripts/ /scripts

RUN cp scripts/bin/* /usr/local/bin && cp scripts/lib/* /usr/lib/ruby/vendor_ruby

USER $GITLAB_USER:$GITLAB_USER

ENTRYPOINT ["/scripts/bin/entrypoint.sh"]
