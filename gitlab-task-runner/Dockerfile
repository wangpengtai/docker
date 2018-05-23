ARG TAG=latest
ARG FROM_IMAGE=registry.gitlab.com/gitlab-org/build/cng/gitlab-rails-ee
FROM ${FROM_IMAGE}:${TAG}

RUN apk update && apk add postgresql openssl tar py-pip && pip install s3cmd==2.0.1

ARG GITLAB_USER=git

COPY scripts/ /scripts
RUN cp /scripts/gitlab-rake /scripts/backup-utility /scripts/s3-simple /usr/local/bin

USER $GITLAB_USER:$GITLAB_USER

ENTRYPOINT ["/scripts/entrypoint.sh"]
