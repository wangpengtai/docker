FROM alpine:3.6

ARG CONFIG=$DATADIR/config/gitlab
ARG CPU_COUNT=4
ARG DATADIR=/var/opt/gitlab
ARG DOMAIN=gitlab.valeriani.co.uk
ARG GITLAB_USER=git
ARG GITLAB_VERSION=10-0-stable-ee
ARG RUBY_MAJOR_VERSION=2.3
ARG RUBY_MINOR_VERSION=2.3.5

# We need the latest and greatest at lesat for yarn
RUN apk update && apk upgrade

# install runtime deps
# busybox contains bug in env command preventing gitaly setup, downgrade it
RUN apk add --no-cache \
        ca-certificates \
        curl \
        git \
        icu-libs \
        libre2 \
        nodejs-lts \
        sudo && \
    apk add busybox=1.25.1-r0 --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/v3.5/main

# install build deps
RUN apk add --no-cache --virtual .build-deps \
        cmake \
        g++ \
        gcc \
        icu-dev \
        libffi-dev \
        libre2-dev \
        linux-headers \
        make \
        musl-dev \
        postgresql-dev \
        zlib-dev

# Install Ruby from source
RUN mkdir /tmp/build && \
    cd /tmp/build && \
    curl -so ruby.tar.bz2 https://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR_VERSION/ruby-$RUBY_MINOR_VERSION.tar.bz2 && \
    tar -xjf ruby.tar.bz2 && \
    rm ruby.tar.bz2 && \
    cd ruby-$RUBY_MINOR_VERSION && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    cd && \
    rm -rf /tmp/build

# create gitlab user
RUN adduser -D -g 'GitLab' $GITLAB_USER

# Install yarn 1.1.0 - There is a bug in yarn < 1.0 - https://gitlab.com/gitlab-org/gitlab-ce/issues/38457
RUN apk --no-cache add bash && \
    sudo -u $GITLAB_USER -H touch /home/$GITLAB_USER/.bashrc && \
    sudo -u $GITLAB_USER -H /usr/bin/curl -so- -L https://yarnpkg.com/install.sh | sudo -u $GITLAB_USER -H /bin/bash && \
    /bin/ln -s /home/$GITLAB_USER/.yarn/bin/yarn /usr/bin/yarn

# $DATADIR is the main mountpoint for gitlab data volume
RUN mkdir $DATADIR && \
    cd $DATADIR && \
    mkdir data repo config && \
    chown -R $GITLAB_USER:$GITLAB_USER $DATADIR

# openssh daemon does not allow locked user to login, change ! to *
RUN sed -i "s/$GITLAB_USER:!/$GITLAB_USER:*/" /etc/shadow && \
    echo "$GITLAB_USER ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers # sudo no tty fix

# adjust git settings
RUN sudo -u $GITLAB_USER -H git config --global gc.auto 0 && \
    sudo -u $GITLAB_USER -H git config --global core.autocrlf input && \
    sudo -u $GITLAB_USER -H git config --global repack.writeBitmaps true

# Download GitLab
RUN cd /home/$GITLAB_USER && \
    sudo -u $GITLAB_USER -H curl -o gitlab.tar.bz2 https://gitlab.com/gitlab-org/gitlab-ee/repository/$GITLAB_VERSION/archive.tar.bz2 && \
    sudo -u $GITLAB_USER -H tar -xjf gitlab.tar.bz2 && \
    mv gitlab-ee-$GITLAB_VERSION-* gitlab && \
    rm gitlab.tar.bz2

# Configure GitLab
RUN cd /home/$GITLAB_USER/gitlab && \
    sudo -u $GITLAB_USER -H mkdir $CONFIG && \
    sudo -u $GITLAB_USER -H cp config/gitlab.yml.example $CONFIG/gitlab.yml && \
    sudo -u $GITLAB_USER -H cp config/unicorn.rb.example $CONFIG/unicorn.rb && \
    sudo -u $GITLAB_USER -H cp config/resque.yml.example $CONFIG/resque.yml && \
    sudo -u $GITLAB_USER -H cp config/secrets.yml.example $CONFIG/secrets.yml && \
    sudo -u $GITLAB_USER -H cp config/database.yml.postgresql $CONFIG/database.yml && \
    sudo -u $GITLAB_USER -H cp config/initializers/rack_attack.rb.example $CONFIG/rack_attack.rb && \
    sudo -u $GITLAB_USER -H ln -s $CONFIG/* config && \
    sudo -u $GITLAB_USER -H mv config/rack_attack.rb config/initializers && \
    sed --in-place "s/# user:.*/user: $GITLAB_USER/" config/gitlab.yml && \
    sed --in-place "s/host: localhost/host: $DOMAIN/" config/gitlab.yml && \
    sed --in-place "s:/home/git/repositories:$DATADIR/repo:" config/gitlab.yml && \
    sed --in-place "s:/home/git:/home/$GITLAB_USER:g" config/unicorn.rb && \
    sed --in-place "s/YOUR_SERVER_FQDN/$DOMAIN/" lib/support/nginx/gitlab

# Move log dir to /var/log data volume mount point
RUN mv /home/$GITLAB_USER/gitlab/log /var/log/gitlab && \
    sudo -u $GITLAB_USER -H ln -s /var/log/gitlab /home/$GITLAB_USER/gitlab/log

# Set permissions
RUN cd /home/$GITLAB_USER/gitlab && \
    chmod o-rwx config/database.yml && \
    chmod 0600 config/secrets.yml && \
    chown -R $GITLAB_USER log/ && \
    chown -R $GITLAB_USER tmp/ && \
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
    sudo -u $GITLAB_USER -H mkdir public/uploads && \
    chmod 0700 public/uploads

# Install bundler
RUN cd /home/$GITLAB_USER/gitlab && \
    gem install bundler --no-ri --no-rdoc

# Maybe we should add these to the upstream Gemfile?
# RUN cd /home/$GITLAB_USER/gitlab && \
#     echo "gem 'bigdecimal'" >> Gemfile && \
#     echo "gem 'tzinfo-data'" >> Gemfile

# Install gems
RUN cd /home/$GITLAB_USER/gitlab && \
    sudo -u git -H bundle install --deployment --without development test mysql aws kerberos

# compile GetText PO files
RUN cd /home/$GITLAB_USER/gitlab && \
    sudo -u $GITLAB_USER -H bundle exec rake gettext:pack RAILS_ENV=production && \
    sudo -u $GITLAB_USER -H bundle exec rake gettext:po_to_json RAILS_ENV=production

# Patch yarn - https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/14543/
COPY patches/yarn.patch /home/$GITLAB_USER/gitlab/
RUN sudo -u $GITLAB_USER -H /home/$GITLAB_USER/gitlab/yarn.patch

# compile assets
RUN cd /home/$GITLAB_USER/gitlab && \
    sudo -u $GITLAB_USER -H yarn install --production --pure-lockfile && \
    sudo -u $GITLAB_USER -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production

# Clean up
RUN rm -rf \
        /home/$GITLAB_USER/gitlab/node_modules \
        /home/$GITLAB_USER/gitlab/tmp \
        /home/$GITLAB_USER/gitlab/spec \
        /home/$GITLAB_USER/gitlab/doc \
        /home/$GITLAB_USER/gitlab/vendor/bundle/ruby/2.4.0/cache \
        /home/$GITLAB_USER/.cache/yarn && \
    apk del .build-deps sudo

VOLUME /var/opt/gitlab /var/log
