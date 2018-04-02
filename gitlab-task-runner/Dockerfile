ARG TAG=latest
FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-rails:${TAG}

RUN apk update && apk add postgresql

ARG GITLAB_USER=git

USER $GITLAB_USER:$GITLAB_USER
COPY scripts/ /scripts

ENTRYPOINT ["/scripts/entrypoint.sh"]
