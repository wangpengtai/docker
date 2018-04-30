ARG TAG=latest
ARG SHELL_CONTAINER=latest
ARG FROM_SHELL_IMAGE=registry.gitlab.com/gitlab-org/build/cng/gitlab-shell
ARG FROM_IMAGE=registry.gitlab.com/gitlab-org/build/cng/gitlab-ruby

FROM ${FROM_SHELL_IMAGE}:${SHELL_CONTAINER} as shell
FROM ${FROM_IMAGE}:${TAG}

ARG GITLAB_USER=git
ARG GITALY_VERSION=v0.52.1
ARG BUILD_DIR=/tmp/build

# install runtime deps
RUN apk add --no-cache \
    icu-libs

# install build deps
RUN apk add --no-cache --virtual .build-deps \
    cmake g++ gcc linux-headers make go sudo icu-dev

# create gitlab user
# openssh daemon does not allow locked user to login, change ! to *
# sudo no tty fix
RUN adduser -D -g 'GitLab' ${GITLAB_USER} && \
    sed -i "s/${GITLAB_USER}:!/${GITLAB_USER}:*/" /etc/shadow && \
    echo "${GITLAB_USER} ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers

# Download and compile Gitaly
ARG CACHE_BUSTER=false
RUN mkdir ${BUILD_DIR} && \
    cd ${BUILD_DIR} && \
    curl -o gitaly.tar.bz2 https://gitlab.com/gitlab-org/gitaly/repository/${GITALY_VERSION}/archive.tar.bz2 && \
    tar -xjf gitaly.tar.bz2 --strip-components=1 && \
    rm gitaly.tar.bz2 && \
    cd ruby && \
    bundle install && \
    bundle exec gem uninstall --force google-protobuf grpc && \
    BUNDLE_FORCE_RUBY_PLATFORM=true bundle install && \
    cd .. && \
    mkdir -p /srv/gitaly-ruby && chown ${GITLAB_USER}:${GITLAB_USER} /srv/gitaly-ruby && \
    cp -r ${BUILD_DIR}/ruby/* /srv/gitaly-ruby/ && \
    touch .ruby-bundle && \
    make install && \
    mkdir -p /etc/gitaly && \
    rm -rf ${BUILD_DIR} /srv/gitaly-ruby/spec  /srv/gitaly-ruby/features

# Include Shell
COPY --from=shell /srv/gitlab-shell /srv/gitlab-shell

RUN cp /srv/gitlab-shell/config.yml.example /etc/gitaly/shell-config.yml && ln -s /etc/gitaly/shell-config.yml /srv/gitlab-shell/config.yml

RUN mkdir -p /var/log/gitaly && \
    touch /var/log/gitaly/gitaly.log && \
    touch /var/log/gitaly/gitlab-shell.log && chown -R ${GITLAB_USER} /var/log/gitaly

RUN apk del .build-deps

# Add scripts
COPY scripts/  /scripts/
COPY config.toml /etc/gitaly/config.toml

RUN chown -R ${GITLAB_USER}:${GITLAB_USER} /etc/gitaly /scripts
USER ${GITLAB_USER}:${GITLAB_USER}

ENV CONFIG_TEMPLATE_DIRECTORY=/etc/gitaly

CMD "/scripts/process-wrapper"

VOLUME /var/log/gitaly

HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
CMD /scripts/healthcheck
