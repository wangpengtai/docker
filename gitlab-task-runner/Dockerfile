ARG TAG=latest
FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-rails:${TAG}

RUN apk update && apk add postgresql openssl

ARG GITLAB_USER=git

COPY scripts/ /scripts
RUN cp /scripts/gitlab-rake /scripts/backup-utility /scripts/s3-simple /usr/local/bin

USER $GITLAB_USER:$GITLAB_USER

ENTRYPOINT ["/scripts/entrypoint.sh"]
