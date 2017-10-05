FROM alpine:3.6

ARG BUILD_DIR=/tmp/build
ARG DATADIR=/var/opt/gitlab
ARG CONFIG=$DATADIR/config/gitlab
ARG CPU_COUNT=4
ARG DOMAIN=gitlab.valeriani.co.uk
ARG GITLAB_USER=git

# Versoins
ARG BUNDLER_VERSION=1.13.6
ARG GIT_VERSION=2.13.5
ARG GITLAB_VERSION=10-0-stable-ee
ARG ICU_VERSION=57.1
ARG ICU_VERSION_UNDERSCORE=57.1
ARG RE2_VERSION=2016-02-01
ARG NODEJS_VERSION=6.9.5
ARG PYTHON_VERSION=3.4.5
ARG RUBY_MAJOR_VERSION=2.3
ARG RUBY_MINOR_VERSION=2.3.5
ARG RUBYGEMS_VERSION=2.6.13
ARG YARN_VERSION=0.20.3

# We need the latest and greatest at lesat for yarn
RUN apk update && apk upgrade

# Install runtime deps
# Busybox contains a bug in the env command breaking the gitaly setup: downgrade it
RUN apk add --no-cache \
        ca-certificates \
        curl \
        sudo && \
    apk add busybox=1.25.1-r0 --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/v3.5/main

# Install build deps and prepare the build environment
RUN apk add --no-cache --virtual .build-deps \
        autoconf \
        cmake \
        g++ \
        gcc \
        gettext \
        libffi-dev \
        linux-headers \
        make \
        musl-dev \
        postgresql-dev \
        zlib-dev && \
    mkdir -p ${BUILD_DIR}

# Install Ruby from source
RUN cd ${BUILD_DIR} && \
    curl -so ruby.tar.bz2 https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR_VERSION}/ruby-${RUBY_MINOR_VERSION}.tar.bz2 && \
    tar -xjf ruby.tar.bz2 && \
    cd ruby-${RUBY_MINOR_VERSION} && \
    ./configure --prefix=/usr && \
    make -j ${CPU_COUNT} && \
    make install && \
    cd && \
    rm -rf ${BUILD_DIR}/ruby.tar.bz2 ${BUILD_DIR}/ruby-${RUBY_MINOR_VERSION}

# Install Python from source
RUN cd ${BUILD_DIR} && \
    curl -so python.tgz https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar -xzf python.tgz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --prefix=/usr && \
    make -j ${CPU_COUNT} && \
    make install && \
    cd && \
    rm -rf ${BUILD_DIR}/python.tgz ${BUILD_DIR}/Python-${PYTHON_VERSION}

# Install git from source
RUN cd ${BUILD_DIR} && \
    curl -o git.tar.gz https://www.kernel.org/pub/software/scm/git/git-2.13.5.tar.gz && \
    tar -xzf git.tar.gz && \
    cd git-$GIT_VERSION && \
    make configure && \
    ./configure --prefix=/usr && \
    make -j ${CPU_COUNT} && \
    make install && \
    cd && \
    rm -rf ${BUILD_DIR}/git.tar.gz ${BUILD_DIR}/git-$GIT_VERSION

# Install re2 from source
RUN cd ${BUILD_DIR} && \
    curl -sLo re2.tar.gz https://github.com/google/re2/archive/$RE2_VERSION.tar.gz && \
    tar -xzf re2.tar.gz && \
    cd re2-$RE2_VERSION && \
    make -j ${CPU_COUNT} && \
    make install && \
    cd && \
    rm -rf ${BUILD_DIR}/re2.tar.gz ${BUILD_DIR}/re2-$RE2_VERSION

# Install icu from source
RUN cd ${BUILD_DIR} && \
    curl -sLo icu.tar.gz http://download.icu-project.org/files/icu4c/$ICU_VERSION/icu4c-${ICU_VERSION_UNDERSCORE}-src.tgz && \
    tar -xzf icu.tar.gz && \
    cd icu/source && \
    ./configure --prefix=/usr && \
    make -j ${CPU_COUNT} && \
    make install && \
    cd && \
    rm -rf ${BUILD_DIR}/icu.tar.gz ${BUILD_DIR}/icu

# Install NodeJS from source
RUN cd ${BUILD_DIR} && \
    curl -sLo nodejs.tar.gz https://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}.tar.gz && \
    tar -xzf nodejs.tar.gz && \
    cd node-v${NODEJS_VERSION} && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    cd && \
    rm -rf ${BUILD_DIR}/nodejs.tar.gz ${BUILD_DIR}/node-v${NODEJS_VERSION}-linux-x64

# create gitlab user
RUN adduser -D -g 'GitLab' ${GITLAB_USER}

# Install yarn 1.1.0 - There is a bug in yarn < 1.0 - https://gitlab.com/gitlab-org/gitlab-ce/issues/38457
RUN apk --no-cache add bash && \
    sudo -u ${GITLAB_USER} -H touch /home/${GITLAB_USER}/.bashrc && \
    sudo -u ${GITLAB_USER} -H /usr/bin/curl -so- -L https://yarnpkg.com/install.sh | sudo -u ${GITLAB_USER} -H /bin/bash && \
    /bin/ln -s /home/${GITLAB_USER}/.yarn/bin/yarn /usr/bin/yarn

# $DATADIR is the main mountpoint for gitlab data volume
RUN mkdir $DATADIR && \
    cd $DATADIR && \
    mkdir data repo config && \
    chown -R ${GITLAB_USER}:${GITLAB_USER} $DATADIR

# openssh daemon does not allow locked user to login, change ! to *
RUN sed -i "s/${GITLAB_USER}:!/${GITLAB_USER}:*/" /etc/shadow && \
    echo "${GITLAB_USER} ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers # sudo no tty fix

# adjust git settings
RUN sudo -u ${GITLAB_USER} -H git config --global gc.auto 0 && \
    sudo -u ${GITLAB_USER} -H git config --global core.autocrlf input && \
    sudo -u ${GITLAB_USER} -H git config --global repack.writeBitmaps true

# Download GitLab
RUN cd /home/${GITLAB_USER} && \
    sudo -u ${GITLAB_USER} -H curl -so gitlab.tar.bz2 https://gitlab.com/gitlab-org/gitlab-ee/repository/$GITLAB_VERSION/archive.tar.bz2 && \
    sudo -u ${GITLAB_USER} -H tar -xjf gitlab.tar.bz2 && \
    mv gitlab-ee-$GITLAB_VERSION-* gitlab && \
    rm gitlab.tar.bz2

# Configure GitLab
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u ${GITLAB_USER} -H mkdir $CONFIG && \
    sudo -u ${GITLAB_USER} -H cp config/gitlab.yml.example $CONFIG/gitlab.yml && \
    sudo -u ${GITLAB_USER} -H cp config/unicorn.rb.example $CONFIG/unicorn.rb && \
    sudo -u ${GITLAB_USER} -H cp config/resque.yml.example $CONFIG/resque.yml && \
    sudo -u ${GITLAB_USER} -H cp config/secrets.yml.example $CONFIG/secrets.yml && \
    sudo -u ${GITLAB_USER} -H cp config/database.yml.postgresql $CONFIG/database.yml && \
    sudo -u ${GITLAB_USER} -H cp config/initializers/rack_attack.rb.example $CONFIG/rack_attack.rb && \
    sudo -u ${GITLAB_USER} -H ln -s $CONFIG/* config && \
    sudo -u ${GITLAB_USER} -H mv config/rack_attack.rb config/initializers && \
    sed --in-place "s/# user:.*/user: ${GITLAB_USER}/" config/gitlab.yml && \
    sed --in-place "s/host: localhost/host: ${DOMAIN}/" config/gitlab.yml && \
    sed --in-place "s:/home/git/repositories:$DATADIR/repo:" config/gitlab.yml && \
    sed --in-place "s:/home/git:/home/${GITLAB_USER}:g" config/unicorn.rb && \
    sed --in-place "s/YOUR_SERVER_FQDN/${DOMAIN}/" lib/support/nginx/gitlab

# Move log dir to /var/log data volume mount point
RUN mv /home/${GITLAB_USER}/gitlab/log /var/log/gitlab && \
    sudo -u ${GITLAB_USER} -H ln -s /var/log/gitlab /home/${GITLAB_USER}/gitlab/log

# Set permissions
RUN cd /home/${GITLAB_USER}/gitlab && \
    chmod o-rwx config/database.yml && \
    chmod 0600 config/secrets.yml && \
    chown -R ${GITLAB_USER} log/ && \
    chown -R ${GITLAB_USER} tmp/ && \
    chmod -R u+rwX,go-w log/ && \
    chmod -R u+rwX tmp/ && \
    chmod -R u+rwX tmp/pids/ && \
    chmod -R u+rwX tmp/sockets/ && \
    chmod -R u+rwX builds/ && \
    chmod -R u+rwX shared/artifacts/ && \
    chmod -R ug+rwX shared/pages/ && \
    chmod -R ug+rwX,o-rwx $DATADIR/repo && \
    chmod -R ug-s $DATADIR/repo && \
    find $DATADIR/repo -type d -print0 | sudo xargs -0 chmod g+s && \
    sudo -u ${GITLAB_USER} -H mkdir public/uploads && \
    chmod 0700 public/uploads

# Install bundler
RUN cd /home/${GITLAB_USER}/gitlab && \
    gem install bundler -v $BUNDLER_VERSION --no-ri --no-rdoc

# Maybe we should add these to the upstream Gemfile?
# RUN cd /home/${GITLAB_USER}/gitlab && \
#     echo "gem 'bigdecimal'" >> Gemfile && \
#     echo "gem 'tzinfo-data'" >> Gemfile

# Install gems
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u git -H bundle install --deployment --without development test mysql aws kerberos

# compile GetText PO files
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u ${GITLAB_USER} -H bundle exec rake gettext:pack RAILS_ENV=production && \
    sudo -u ${GITLAB_USER} -H bundle exec rake gettext:po_to_json RAILS_ENV=production

# Patch yarn - https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/14543/
COPY patches/yarn.patch /home/${GITLAB_USER}/gitlab/
RUN sudo -u ${GITLAB_USER} -H /home/${GITLAB_USER}/gitlab/yarn.patch

# compile assets
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u ${GITLAB_USER} -H yarn install --production --pure-lockfile && \
    sudo -u ${GITLAB_USER} -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production

# Clean up
RUN rm -rf \
        /home/${GITLAB_USER}/gitlab/node_modules \
        /home/${GITLAB_USER}/gitlab/tmp \
        /home/${GITLAB_USER}/gitlab/spec \
        /home/${GITLAB_USER}/gitlab/doc \
        /home/${GITLAB_USER}/gitlab/vendor/bundle/ruby/2.4.0/cache \
        /home/${GITLAB_USER}/.cache/yarn \
        ${BUILD_DIR} && \
    apk del .build-deps sudo

VOLUME /var/opt/gitlab /var/log
