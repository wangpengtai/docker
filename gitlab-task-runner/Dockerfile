ARG TAG=latest
ARG FROM_IMAGE=registry.gitlab.com/gitlab-org/build/cng/gitlab-rails-ee
FROM ${FROM_IMAGE}:${TAG}

RUN apk update && apk add postgresql openssl tar py-pip && pip install s3cmd==2.0.1

ARG GITLAB_USER=git

COPY scripts/ /scripts

RUN cp /scripts/* /usr/local/bin && cp /scripts/object_storage_backup.rb /usr/lib/ruby/vendor_ruby

USER $GITLAB_USER:$GITLAB_USER

ENTRYPOINT ["/scripts/entrypoint.sh"]
