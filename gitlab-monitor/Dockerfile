ARG CI_REGISTRY_IMAGE="registry.gitlab.com/gitlab-org/build/cng"
ARG TAG=latest
ARG FROM_IMAGE="$CI_REGISTRY_IMAGE/gitlab-ruby"
ARG GITLAB_MONITOR_VERSION=v4.0.0
FROM ${FROM_IMAGE}:${TAG}

ARG GITLAB_USER=git
ARG BUILD_DIR=/tmp/build
ARG GITLAB_MONITOR_VERSION

# create gitlab user
# openssh daemon does not allow locked user to login, change ! to *
RUN adduser --disabled-password --gecos 'GitLab' ${GITLAB_USER} && \
    sed -i "s/${GITLAB_USER}:!/${GITLAB_USER}:*/" /etc/shadow

# install build deps
RUN buildDeps='build-essential git' && \
    apt-get update && \
    apt-get install -y --no-install-recommends $buildDeps libpq-dev && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p ${BUILD_DIR} && \
    chown ${GITLAB_USER}:${GITLAB_USER} ${BUILD_DIR} && \
    cd ${BUILD_DIR} && \
    echo "Cloning source code from https://gitlab.com/gitlab-org/gitlab-monitor.git" && \
    git clone --branch ${GITLAB_MONITOR_VERSION} https://gitlab.com/gitlab-org/gitlab-monitor.git && \
    cd gitlab-monitor && \
    gem build gitlab-monitor.gemspec && \
    gem install gitlab-monitor && \
    SUDO_FORCE_REMOVE=yes apt-get purge -y --auto-remove $buildDeps && \
    rm -rf ${BUILD_DIR}

RUN mkdir -p /etc/gitlab-monitor; chown -R $GITLAB_USER /etc/gitlab-monitor

USER $GITLAB_USER:$GITLAB_USER

ENV CONFIG_TEMPLATE_DIRECTORY=/var/opt/gitlab-monitor/templates
ENV CONFIG_DIRECTORY=/etc/gitlab-monitor

CMD ["/usr/bin/gitlab-mon", "web", "-c", "/etc/gitlab-monitor/gitlab-monitor.yml"]
