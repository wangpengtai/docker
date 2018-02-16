ARG TAG=latest
FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-ruby:${TAG} as builder

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

# install build deps
RUN apk add --no-cache \
        icu-libs=58.2-r2 \
        libre2=2017.05.01-r0 \
        tzdata=2017a-r0 \
        libc6-compat=1.1.16-r14 \
        postgresql-client=9.6.7-r0 \
        sudo=1.8.19_p2-r0 \
        busybox=1.26.2-r9 \
        cmake=3.8.1-r0 \
        g++=6.3.0-r4\
        gcc=6.3.0-r4 \
        icu-dev=58.2-r2 \
        libffi-dev=3.2.1-r3 \
        libre2-dev=2017.05.01-r0 \
        nodejs=6.10.3-r1 \
        linux-headers=4.4.6-r2 \
        make=4.2.1-r0 \
        musl-dev=1.1.16-r14 \
        postgresql-dev=9.6.7-r0 \
        zlib-dev=1.2.11-r0 \
        bash=4.3.48-r1 && \
        mkdir -p ${BUILD_DIR}

# create gitlab user
RUN adduser -D -g 'GitLab' ${GITLAB_USER}

RUN sudo -u $GITLAB_USER -H touch /home/${GITLAB_USER}/.bashrc && \
    sudo -u $GITLAB_USER -H /usr/bin/curl -so- -L https://yarnpkg.com/install.sh | sudo -u ${GITLAB_USER} -H /bin/bash -s -- --version ${YARN_VERSION} && \
    /bin/ln -s /home/${GITLAB_USER}/.yarn/bin/yarn /usr/bin/yarn

# $DATADIR is the main mountpoint for gitlab data volume
RUN mkdir ${DATADIR} && \
    cd ${DATADIR} && \
    mkdir data repo config && \
    chown -R ${GITLAB_USER}:${GITLAB_USER} ${DATADIR}

# Download GitLab
ARG CACHE_BUSTER=false
RUN cd /home/${GITLAB_USER} && \
    sudo -u ${GITLAB_USER} -H curl -o gitlab.tar.bz2 https://gitlab.com/gitlab-org/gitlab-ee/repository/${GITLAB_VERSION}/archive.tar.bz2 && \
    sudo -u ${GITLAB_USER} -H tar -xjf gitlab.tar.bz2 && \
    REVISION=$(find -maxdepth 1 -name gitlab-ee-${GITLAB_VERSION}-* -print | awk -F '-' '{print $NF}' | cut -c -8) && \
    mv gitlab-ee-${GITLAB_VERSION}-* gitlab && \
    echo -n ${REVISION} > gitlab/REVISION && \
    rm gitlab.tar.bz2

# Configure GitLab
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u ${GITLAB_USER} -H mkdir ${CONFIG} && \
    sudo -u ${GITLAB_USER} -H mkdir ${DATADIR}/.upgrade-status && \
    sudo -u ${GITLAB_USER} -H cp config/gitlab.yml.example ${CONFIG}/gitlab.yml && \
    sudo -u ${GITLAB_USER} -H cp config/resque.yml.example ${CONFIG}/resque.yml && \
    sudo -u ${GITLAB_USER} -H cp config/secrets.yml.example ${CONFIG}/secrets.yml && \
    sudo -u ${GITLAB_USER} -H cp config/database.yml.postgresql ${CONFIG}/database.yml && \
    sudo -u ${GITLAB_USER} -H cp config/initializers/rack_attack.rb.example ${CONFIG}/rack_attack.rb && \
    sudo -u ${GITLAB_USER} -H ln -s ${CONFIG}/* config && \
    sudo -u ${GITLAB_USER} -H mv config/rack_attack.rb config/initializers && \
    sed --in-place "s/.*REVISION.*/REVISION = '$(cat REVISION)'/" config/initializers/2_app.rb && \
    sed --in-place "/host: localhost/d" ${CONFIG}/gitlab.yml && \
    sed --in-place "/port: 80/d" ${CONFIG}/gitlab.yml && \
    sed --in-place "s/# user:.*/user: ${GITLAB_USER}/" ${CONFIG}/gitlab.yml && \
    sed --in-place "s:/home/git/repositories:${DATADIR}/repo:" ${CONFIG}/gitlab.yml

# Install gems
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u git -H bundle install --deployment --without development test mysql aws kerberos --jobs 4 --retry 5

# Some Gems are skipping extension compilation on alpine for some reason, Force them to compile
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u ${GITLAB_USER} -H bundle exec gem uninstall --force google-protobuf grpc && \
    sudo -u ${GITLAB_USER} -H BUNDLE_FORCE_RUBY_PLATFORM=true bundle install

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
        /home/${GITLAB_USER}/gitlab/vendor/bundle/ruby/*/cache && \
    find /home/${GITLAB_USER}/gitlab -name '*.gem' -type f -print -delete && \
    find /home/${GITLAB_USER}/gitlab/vendor/bundle/ruby/*/gems -name 'doc' -type d -print -exec rm -r {} +

# Final image
FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-ruby:${TAG}
ARG DATADIR=/var/opt/gitlab
ARG CONFIG=$DATADIR/config/gitlab
ARG GITLAB_USER=git

RUN apk add --no-cache \
        icu-libs=58.2-r2 \
        libre2=2017.05.01-r0 \
        tzdata=2017a-r0 \
        libc6-compat=1.1.16-r14 \
        postgresql-client=9.6.7-r0 \
        sudo=1.8.19_p2-r0 \
        busybox=1.26.2-r9

RUN adduser -D -g 'GitLab' ${GITLAB_USER}
# adjust git settings

RUN sudo -u ${GITLAB_USER} -H git config --global gc.auto 0 && \
    sudo -u ${GITLAB_USER} -H git config --global core.autocrlf input && \
    sudo -u ${GITLAB_USER} -H git config --global repack.writeBitmaps true

COPY --chown=git --from=builder /home/git/gitlab /home/git/gitlab
COPY --chown=git --from=builder /var/opt/gitlab /var/opt/gitlab

RUN mv /home/${GITLAB_USER}/gitlab/log /var/log/gitlab && \
    ln -s /var/log/gitlab /home/${GITLAB_USER}/gitlab/log && \
    cd /home/${GITLAB_USER}/gitlab && \
    chmod o-rwx config/database.yml && \
    chmod 0600 config/secrets.yml && \
    chmod -R u+rwX builds/ && \
    chmod -R u+rwX shared/artifacts/ && \
    chmod -R ug+rwX shared/pages/ && \
    chmod -R ug+rwX,o-rwx ${DATADIR}/repo && \
    chmod -R ug-s ${DATADIR}/repo && \
    find ${DATADIR}/repo -type d -print0 | sudo xargs -0 chmod g+s && \
    mkdir -p public/uploads && \
    chmod 0700 public/uploads

COPY scripts/ /scripts

RUN chown -R ${GITLAB_USER} /scripts

ENV RAILS_ENV=production \
    EXECJS_RUNTIME=Disabled \
    CONFIG_TEMPLATE_DIRECTORY=${CONFIG} \
    UPGRADE_STATUS_DIR=${DATADIR}/.upgrade-status

VOLUME /var/opt/gitlab /var/log
