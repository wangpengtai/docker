ARG TAG=latest
FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-ruby:${TAG}

ARG GITLAB_SHELL_VERSION=master
ARG GITLAB_USER=git

# install runtime deps
RUN apk add --no-cache \
        openssh

# install build deps
RUN apk add --no-cache --virtual .build-deps \
        cmake g++ gcc linux-headers make go sudo

# create gitlab user
# openssh daemon does not allow locked user to login, change ! to *
RUN adduser -D -g 'GitLab' ${GITLAB_USER} && \
    sed -i "s/${GITLAB_USER}:!/${GITLAB_USER}:*/" /etc/shadow

# Create a run environment for SSHD
RUN mkdir /srv/sshd && chown ${GITLAB_USER}:${GITLAB_USER} /srv/sshd

# Download and compile GitLab Shell
ARG CACHE_BUSTER=false
RUN mkdir /srv/gitlab-shell && chown ${GITLAB_USER}:${GITLAB_USER} /srv/gitlab-shell && \
    cd /srv/gitlab-shell && \
    sudo -u ${GITLAB_USER} -H curl -o gitlab-shell.tar.bz2 https://gitlab.com/gitlab-org/gitlab-shell/repository/${GITLAB_SHELL_VERSION}/archive.tar.bz2 && \
    sudo -u ${GITLAB_USER} -H tar -xjf gitlab-shell.tar.bz2 --strip-components=1 && \
    rm gitlab-shell.tar.bz2 && \
    ./bin/compile

RUN mkdir -p /var/log/gitlab-shell && chown ${GITLAB_USER} /var/log/gitlab-shell && \
    sudo -u ${GITLAB_USER} -H touch /var/log/gitlab-shell/gitlab-shell.log

RUN apk del .build-deps

# Add scripts
COPY scripts/  /scripts/
COPY sshd_config /etc/ssh/

# AuthrorizedKeysCommand must be owned by root, and have all parent paths owned as root
RUN mv /scripts/authorized_keys /authorized_keys && chmod 0755 /authorized_keys

RUN chown -R $GITLAB_USER:$GITLAB_USER /scripts /etc/ssh

USER $GITLAB_USER:$GITLAB_USER

ENV CONFIG_TEMPLATE_DIRECTORY=/srv/gitlab-shell

CMD "/scripts/process-wrapper"

VOLUME /var/log/gitlab-shell

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
CMD /scripts/healthcheck
