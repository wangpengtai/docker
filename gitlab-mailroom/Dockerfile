ARG TAG=latest
ARG FROM_IMAGE=registry.gitlab.com/gitlab-org/build/cng/gitlab-ruby

FROM ${FROM_IMAGE}:${TAG}

ARG MAILROOM_VERSION=0.9.1
ARG GITLAB_USER=git

RUN adduser --disabled-password --gecos 'GitLab' ${GITLAB_USER} && \
    sed -i "s/${GITLAB_USER}:!/${GITLAB_USER}:*/" /etc/shadow && \
    mkdir /var/log/gitlab && \
    touch /var/log/gitlab/mail_room.log && \
    chown -R ${GITLAB_USER}:${GITLAB_USER} /var/log/gitlab

COPY scripts/  /scripts/

RUN MAILROOM_VERSION=${MAILROOM_VERSION} /scripts/install-dependencies && rm /scripts/install-dependencies
CMD /scripts/process-wrapper
