ARG TAG=latest
FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-ruby:${TAG}

ARG GITLAB_SHELL_VERSION=5.9.4
ARG GITLAB_USER=git

# install build deps
RUN apk add --no-cache --virtual .build-deps \
        cmake g++ gcc linux-headers make go sudo

# create gitlab user
# openssh daemon does not allow locked user to login, change ! to *
# sudo no tty fix
RUN adduser -D -g 'GitLab' ${GITLAB_USER} && \
    sed -i "s/${GITLAB_USER}:!/${GITLAB_USER}:*/" /etc/shadow && \
    echo "${GITLAB_USER} ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers

# Download and compile GitLab Shell
RUN mkdir /srv/gitlab-shell && chown ${GITLAB_USER}:${GITLAB_USER} /srv/gitlab-shell && \
    cd /srv/gitlab-shell && \
    sudo -u ${GITLAB_USER} -H curl -o gitlab-shell.tar.bz2 https://gitlab.com/gitlab-org/gitlab-shell/repository/v${GITLAB_SHELL_VERSION}/archive.tar.bz2 && \
    sudo -u ${GITLAB_USER} -H tar -xjf gitlab-shell.tar.bz2 --strip-components=1 && \
    rm gitlab-shell.tar.bz2 && \
    ./bin/compile

RUN mkdir -p /var/log/gitlab-shell && chown ${GITLAB_USER} /var/log/gitlab-shell

RUN apk del .build-deps

VOLUME /var/log/gitlab-shell

CMD bash
