ARG TAG=latest
ARG FROM_IMAGE=registry.gitlab.com/gitlab-org/build/cng/gitlab-ruby

FROM ${FROM_IMAGE}:${TAG} as builder

ARG BUILD_DIR=/tmp/build
ARG DATADIR=/var/opt/gitlab
ARG CONFIG=$DATADIR/config/gitlab
ARG CPU_COUNT=4
ARG GITLAB_USER=git
ARG GITLAB_VERSION=v10.7.0-ee
ARG GITLAB_EDITION=gitlab-ee
ARG COMPILE_ASSETS_ENV="RAILS_ENV=production NODE_ENV=production USE_DB=false SKIP_STORAGE_VALIDATION=true"
ARG NODE_VERSION=8.9.4
ARG YARN_VERSION=0.20.3

# install runtime deps
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=866729
RUN mkdir -p /usr/share/man/man7 \
    && apt-get update \
    && apt-get install -y --no-install-recommends libicu57 libre2-3 tzdata postgresql-client-9.6=9.6.7-0+deb9u1

RUN buildDeps=' \
    make \
    cmake \
    gcc \
    g++ \
    libicu-dev \
    libffi-dev \
    libre2-dev \
    musl-dev \
    pkg-config \
    libkrb5-3 \
    libpq-dev \
    sudo' \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p ${BUILD_DIR}

RUN curl -fsSL "https://nodejs.org/download/release/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz" \
  | tar --strip-components 1 -xzC /usr/local/

RUN mkdir /usr/local/yarn \
  && curl -fsSL "https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-v${YARN_VERSION}.tar.gz" \
  | tar -xzC /usr/local/yarn --strip 1 \
  && ln -sf /usr/local/yarn/bin/yarn /usr/local/bin/

# create gitlab user
RUN adduser --disabled-password --gecos 'GitLab' ${GITLAB_USER}

# $DATADIR is the main mountpoint for gitlab data volume
RUN mkdir ${DATADIR} && \
    cd ${DATADIR} && \
    mkdir data repo config && \
    chown -R ${GITLAB_USER}:${GITLAB_USER} ${DATADIR}

# Download GitLab
ARG CACHE_BUSTER=false
RUN cd /home/${GITLAB_USER} && \
    sudo -u ${GITLAB_USER} -H curl -o gitlab.tar.bz2 https://gitlab.com/gitlab-org/${GITLAB_EDITION}/repository/${GITLAB_VERSION}/archive.tar.bz2 && \
    sudo -u ${GITLAB_USER} -H tar -xjf gitlab.tar.bz2 && \
    REVISION=$(find -maxdepth 1 -name ${GITLAB_EDITION}-${GITLAB_VERSION}-* -print | awk -F '-' '{print $NF}' | cut -c -8) && \
    mv ${GITLAB_EDITION}-${GITLAB_VERSION}-* gitlab && \
    echo -n ${REVISION} > gitlab/REVISION && \
    rm gitlab.tar.bz2

# Configure GitLab
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u ${GITLAB_USER} -H mkdir ${CONFIG} && \
    sudo -u ${GITLAB_USER} -H mkdir ${DATADIR}/.upgrade-status && \
    sudo -u ${GITLAB_USER} -H echo 'gitlab-cloud-native-image' > INSTALLATION_TYPE && \
    sudo -u ${GITLAB_USER} -H cp config/gitlab.yml.example ${CONFIG}/gitlab.yml && \
    sudo -u ${GITLAB_USER} -H cp config/resque.yml.example ${CONFIG}/resque.yml && \
    sudo -u ${GITLAB_USER} -H cp config/secrets.yml.example ${CONFIG}/secrets.yml && \
    sudo -u ${GITLAB_USER} -H cp config/database.yml.postgresql ${CONFIG}/database.yml && \
    sudo -u ${GITLAB_USER} -H cp config/initializers/rack_attack.rb.example ${CONFIG}/rack_attack.rb && \
    sudo -u ${GITLAB_USER} -H ln -s ${CONFIG}/* config && \
    sudo -u ${GITLAB_USER} -H mv config/rack_attack.rb config/initializers && \
    sed --in-place "/host: localhost/d" ${CONFIG}/gitlab.yml && \
    sed --in-place "/port: 80/d" ${CONFIG}/gitlab.yml && \
    sed --in-place "s/# user:.*/user: ${GITLAB_USER}/" ${CONFIG}/gitlab.yml && \
    sed --in-place "s:/home/git/repositories:${DATADIR}/repo:" ${CONFIG}/gitlab.yml

# Install gems
RUN cd /home/${GITLAB_USER}/gitlab && \
    sudo -u git -H bundle install --deployment --without development test mysql aws kerberos --jobs 4 --retry 5

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

# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=866729
RUN mkdir -p /usr/share/man/man7 \
    && apt-get update \
    && apt-get install -y --no-install-recommends libicu57 libre2-3 tzdata postgresql-client-9.6=9.6.7-0+deb9u1

RUN buildDeps=' \
    libicu-dev \
    libffi-dev \
    libre2-dev \
    libedit-dev \
    libxml2-dev \
    sudo' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos 'GitLab' ${GITLAB_USER}

COPY --from=builder /usr/bin/pg_* /usr/bin/
COPY --from=builder /usr/bin/psql /usr/bin/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libpq.so* /usr/lib/x86_64-linux-gnu/

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
    mkdir -p public/uploads && chown ${GITLAB_USER}:${GITLAB_USER} public/uploads && \
    chmod 0700 public/uploads

COPY scripts/ /scripts

RUN chown -R ${GITLAB_USER} /scripts

ENV RAILS_ENV=production \
    EXECJS_RUNTIME=Disabled \
    CONFIG_TEMPLATE_DIRECTORY=${CONFIG} \
    UPGRADE_STATUS_DIR=${DATADIR}/.upgrade-status

VOLUME /var/opt/gitlab /var/log
