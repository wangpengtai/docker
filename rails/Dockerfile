ARG TAG=latest
FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-ruby:${TAG}

ARG BUILD_DIR=/tmp/build
ARG DATADIR=/var/opt/gitlab
ARG CONFIG=$DATADIR/config/gitlab
ARG CPU_COUNT=4
ARG GITLAB_USER=git
ARG GITLAB_VERSION=v10.2.0-ee
ARG YARN_VERSION=0.20.3
ARG COMPILE_ASSETS_ENV="RAILS_ENV=production NODE_ENV=production USE_DB=false SKIP_STORAGE_VALIDATION=true"

# We need the latest and greatest at lesat for yarn
RUN apk update && apk upgrade

# install runtime deps
RUN apk add --no-cache \
        icu-libs \
        libre2 \
        tzdata \
        libc6-compat \
        postgresql-client \
        sudo \
        busybox

# install build deps
RUN apk add --no-cache --virtual .build-deps \
        cmake \
        g++ \
        gcc \
        icu-dev \
        libffi-dev \
        libre2-dev \
        nodejs-lts \
        linux-headers \
        make \
        musl-dev \
        postgresql-dev \
        zlib-dev && \
        mkdir -p ${BUILD_DIR}

# create gitlab user
RUN adduser -D -g 'GitLab' ${GITLAB_USER}

RUN apk --no-cache add bash && \
    sudo -u $GITLAB_USER -H touch /home/${GITLAB_USER}/.bashrc && \
    sudo -u $GITLAB_USER -H /usr/bin/curl -so- -L https://yarnpkg.com/install.sh | sudo -u ${GITLAB_USER} -H /bin/bash -s -- --version ${YARN_VERSION} && \
    /bin/ln -s /home/${GITLAB_USER}/.yarn/bin/yarn /usr/bin/yarn

# $DATADIR is the main mountpoint for gitlab data volume
RUN mkdir ${DATADIR} && \
    cd ${DATADIR} && \
    mkdir data repo config && \
    chown -R ${GITLAB_USER}:${GITLAB_USER} ${DATADIR}

# openssh daemon does not allow locked user to login, change ! to *
RUN sed -i "s/${GITLAB_USER}:!/${GITLAB_USER}:*/" /etc/shadow && \
    echo "${GITLAB_USER} ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers # sudo no tty fix

# adjust git settings
RUN sudo -u ${GITLAB_USER} -H git config --global gc.auto 0 && \
    sudo -u ${GITLAB_USER} -H git config --global core.autocrlf input && \
    sudo -u ${GITLAB_USER} -H git config --global repack.writeBitmaps true

# Download GitLab
RUN cd /home/${GITLAB_USER} && \
    sudo -u ${GITLAB_USER} -H curl -o gitlab.tar.bz2 https://gitlab.com/gitlab-org/gitlab-ee/repository/${GITLAB_VERSION}/archive.tar.bz2 && \
    sudo -u ${GITLAB_USER} -H tar -xjf gitlab.tar.bz2 && \
    mv gitlab-ee-${GITLAB_VERSION}-* gitlab && \
    rm gitlab.tar.bz2

# Configure GitLab
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u ${GITLAB_USER} -H mkdir ${CONFIG} && \
    sudo -u ${GITLAB_USER} -H cp config/gitlab.yml.example ${CONFIG}/gitlab.yml && \
    sudo -u ${GITLAB_USER} -H cp config/unicorn.rb.example ${CONFIG}/unicorn.rb && \
    sudo -u ${GITLAB_USER} -H cp config/resque.yml.example ${CONFIG}/resque.yml && \
    sudo -u ${GITLAB_USER} -H cp config/secrets.yml.example ${CONFIG}/secrets.yml && \
    sudo -u ${GITLAB_USER} -H cp config/database.yml.postgresql ${CONFIG}/database.yml && \
    sudo -u ${GITLAB_USER} -H cp config/initializers/rack_attack.rb.example ${CONFIG}/rack_attack.rb && \
    sudo -u ${GITLAB_USER} -H ln -s ${CONFIG}/* config && \
    sudo -u ${GITLAB_USER} -H mv config/rack_attack.rb config/initializers && \
    sed --in-place "/host: localhost/d" config/gitlab.yml && \
    sed --in-place "/port: 80/d" config/gitlab.yml && \
    sed --in-place "s/# user:.*/user: ${GITLAB_USER}/" config/gitlab.yml && \
    sed --in-place "s:/home/git/repositories:${DATADIR}/repo:" config/gitlab.yml && \
    sed --in-place "s:/home/git:/home/${GITLAB_USER}:g" config/unicorn.rb

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
    chmod -R ug+rwX,o-rwx ${DATADIR}/repo && \
    chmod -R ug-s ${DATADIR}/repo && \
    find ${DATADIR}/repo -type d -print0 | sudo xargs -0 chmod g+s && \
    sudo -u ${GITLAB_USER} -H mkdir public/uploads && \
    chmod 0700 public/uploads

# Maybe we should add these to the upstream Gemfile?
# RUN cd /home/${GITLAB_USER}/gitlab && \
#     echo "gem 'bigdecimal'" >> Gemfile && \
#     echo "gem 'tzinfo-data'" >> Gemfile

# Install gems
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u git -H bundle install --deployment --without development test mysql aws kerberos --jobs 4 --retry 5

# Some Gems are skipping extension compilation on alpine for some reason, Force them to compile
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u git -H bundle exec gem uninstall --force google-protobuf grpc && \
    sudo -u git -H BUNDLE_FORCE_RUBY_PLATFORM=true bundle install

# Install node dependencies
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u ${GITLAB_USER} -H $COMPILE_ASSETS_ENV yarn install --production --pure-lockfile

# compile GetText PO files
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u ${GITLAB_USER} -H $COMPILE_ASSETS_ENV bundle exec rake gettext:compile

# compile assets
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u ${GITLAB_USER} -H $COMPILE_ASSETS_ENV bundle exec rake gitlab:assets:compile

# Clean up
RUN rm -rf \
        /home/${GITLAB_USER}/gitlab/node_modules \
        /home/${GITLAB_USER}/gitlab/tmp \
        /home/${GITLAB_USER}/gitlab/spec \
        /home/${GITLAB_USER}/gitlab/vendor/bundle/ruby/*/cache \
        /home/${GITLAB_USER}/.cache/yarn && \
    find /home/${GITLAB_USER}/gitlab -name '*.gem' -type f -print -delete && \
    find /home/${GITLAB_USER}/gitlab/vendor/bundle/ruby/*/gems -name 'doc' -type d -print -exec rm -r {} + && \
    apk del .build-deps sudo

# Add scripts
COPY scripts/ /scripts

ENV RAILS_ENV=production \
    EXECJS_RUNTIME=Disabled \
    CONFIG_TEMPLATE_DIRECTORY=${CONFIG} \
    CACHEBUST=trust

ENTRYPOINT ["/scripts/entrypoint.sh"]

VOLUME /var/opt/gitlab /var/log
