ARG TAG=latest
FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-rails:${TAG}

RUN apk update && apk add postgresql openssl

ARG GITLAB_USER=git

COPY scripts/ /scripts
RUN ln -s /scripts/gitlab-rake /usr/local/bin/gitlab-rake && \
    ln -s /scripts/backup-utility /usr/local/bin/backup-utility && \
    ln -s /scripts/s3-simple /usr/local/bin/s3-simple

USER $GITLAB_USER:$GITLAB_USER

ENTRYPOINT ["/scripts/entrypoint.sh"]
