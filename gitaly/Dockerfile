ARG TAG=latest
ARG SHELL_CONTAINER=latest
ARG FROM_SHELL_IMAGE=registry.gitlab.com/gitlab-org/build/cng/gitlab-shell
ARG FROM_IMAGE=registry.gitlab.com/gitlab-org/build/cng/gitlab-ruby

FROM ${FROM_SHELL_IMAGE}:${SHELL_CONTAINER} as shell
FROM ${FROM_IMAGE}:${TAG}

ARG GITLAB_USER=git
ARG GITALY_VERSION=v0.96.1
ARG BUILD_DIR=/tmp/build
ARG GO_VERSION=1.9.6
ARG GIT_VERSION=2.17.1

# install runtime deps
RUN apt-get update \
    && apt-get install -y --no-install-recommends libicu57 libpcre2-dev libcurl4-gnutls-dev

RUN buildDeps=' \
    make \
    cmake \
    gcc \
    g++ \
    libicu-dev \
    pkg-config \
    sudo' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p ${BUILD_DIR}

# install go
RUN cd ${BUILD_DIR} \
  && curl -so golang.tar.xz "https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz" \
  && tar -xf golang.tar.xz \
  && mv ${BUILD_DIR}/go /usr/local/go \
  && rm golang.tar.xz \
  && rm -rf /var/lib/apt/lists/* \
  && ln -sf /usr/local/go/bin/go /usr/local/go/bin/gofmt /usr/local/go/bin/godoc /usr/local/bin/

RUN cd ${BUILD_DIR} \
    && curl -so git.tar.gz "https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz" \
    && tar -xf git.tar.gz \
    && cd ${BUILD_DIR}/git-${GIT_VERSION} \
    && echo "USE_LIBPCRE2=YesPlease \n\
NO_PERL=YesPlease \n\
NO_EXPAT=YesPlease \n\
NO_TCLTK=YesPlease \n\
NO_GETTEXT=YesPlease\n\
NO_PYTHON=YesPlease \n\
NO_INSTALL_HARDLINKS=YesPlease \n\
NO_R_TO_GCC_LINKER=YesPlease" > config.mak \
    && make all prefix=/usr/local \
    && make install prefix=/usr/local \
    && cd .. \
    && rm -rf git.tar.gz git-${GIT_VERSION}

# create gitlab user
# openssh daemon does not allow locked user to login, change ! to *
RUN adduser --disabled-password --gecos 'GitLab' ${GITLAB_USER} && \
      sed -i "s/${GITLAB_USER}:!/${GITLAB_USER}:*/" /etc/shadow

# adjust git settings
RUN sudo -u ${GITLAB_USER} -H git config --global gc.auto 0 && \
    sudo -u ${GITLAB_USER} -H git config --global core.autocrlf input && \
    sudo -u ${GITLAB_USER} -H git config --global repack.writeBitmaps true

# Download and compile Gitaly
ARG CACHE_BUSTER=false
RUN cd ${BUILD_DIR} && \
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

RUN buildDeps=' \
    make \
    cmake \
    gcc \
    g++ \
    libicu-dev \
    sudo' \
    && SUDO_FORCE_REMOVE=yes apt-get purge -y --auto-remove $buildDeps \
    && rm -rf ${BUILD_DIR}


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
