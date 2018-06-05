ARG TAG=latest
ARG FROM_IMAGE=registry.gitlab.com/gitlab-org/build/cng/gitlab-ruby

FROM ${FROM_IMAGE}:${TAG}

ARG BUILD_DIR=/tmp/build
ARG GITLAB_SHELL_VERSION=master
ARG GITLAB_USER=git
ARG GO_VERSION=1.9.6

# install runtime deps
RUN apt-get update \
  && apt-get install -y --no-install-recommends openssh-server \
  && rm -rf /var/lib/apt/lists/*

# install build deps
RUN buildDeps=' \
    sudo' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p ${BUILD_DIR}

RUN cd ${BUILD_DIR} \
  && curl -so golang.tar.xz "https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz" \
  && tar -xf golang.tar.xz \
  && mv ${BUILD_DIR}/go /usr/local/go \
  && rm golang.tar.xz \
  && rm -rf /var/lib/apt/lists/* \
  && ln -sf /usr/local/go/bin/go /usr/local/go/bin/gofmt /usr/local/go/bin/godoc /usr/local/bin/

# create gitlab user
# openssh daemon does not allow locked user to login, change ! to *
RUN adduser --disabled-password --gecos 'GitLab' ${GITLAB_USER} && \
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

RUN buildDeps=' \
    sudo' \
    && SUDO_FORCE_REMOVE=yes apt-get purge -y --auto-remove $buildDeps \
    && rm -rf ${BUILD_DIR}

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
