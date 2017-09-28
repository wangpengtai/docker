FROM alpine:3.6

ARG VERSION=10-0-stable
ARG DOMAIN=gitlab.valeriani.co.uk
ARG USER=git
ARG DATADIR=/var/opt/gitlab
ARG CONFIG=$DATADIR/config/gitlab
ARG CPU_COUNT=4

# We need the latest and greatest at lesat for yarn
RUN apk update && apk upgrade

# install runtime deps
RUN apk add --no-cache \
        ca-certificates \
        curl \
        git \
        icu-libs \
        libre2 \
        nodejs-lts \
        ruby \
        ruby-io-console \
        ruby-irb \
        sudo && \
    # busybox contains bug in env command preventing gitaly setup, downgrade it
    apk add busybox=1.25.1-r0 --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/v3.5/main && \
    # install build deps
    apk add --no-cache --virtual .build-deps \
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
        python2 \
        ruby-dev \
        zlib-dev

# create gitlab user
RUN adduser -D -g 'GitLab' $USER

# Install yarn 1.1.0 - There is a bug in yarn < 1.0 - https://gitlab.com/gitlab-org/gitlab-ce/issues/38457
RUN apk --no-cache add bash && \
    sudo -u $USER -H touch /home/$USER/.bashrc && \
    sudo -u $USER -H /usr/bin/curl -so- -L https://yarnpkg.com/install.sh | sudo -u $USER -H /bin/bash && \
    /bin/ln -s /home/$USER/.yarn/bin/yarn /usr/bin/yarn

# $DATADIR is the main mountpoint for gitlab data volume
RUN mkdir $DATADIR && \
    cd $DATADIR && \
    mkdir data repo config && \
    chown -R $USER:$USER $DATADIR

# openssh daemon does not allow locked user to login, change ! to *
RUN sed -i "s/$USER:!/$USER:*/" /etc/shadow && \
    echo "$USER ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers # sudo no tty fix

# adjust git settings
RUN sudo -u $USER -H git config --global gc.auto 0 && \
    sudo -u $USER -H git config --global core.autocrlf input && \
    sudo -u $USER -H git config --global repack.writeBitmaps true

# Download GitLab
RUN cd /home/$USER && \
    sudo -u $USER -H curl -o gitlab.tar.bz2 https://gitlab.com/gitlab-org/gitlab-ce/repository/$VERSION/archive.tar.bz2 && \
    sudo -u $USER -H tar -xjf gitlab.tar.bz2 && \
    mv gitlab-ce-$VERSION-* gitlab && \
    rm gitlab.tar.bz2

# Configure GitLab
RUN cd /home/$USER/gitlab && \
    sudo -u $USER -H mkdir $CONFIG && \
    sudo -u $USER -H cp config/gitlab.yml.example $CONFIG/gitlab.yml && \
    sudo -u $USER -H cp config/unicorn.rb.example $CONFIG/unicorn.rb && \
    sudo -u $USER -H cp config/resque.yml.example $CONFIG/resque.yml && \
    sudo -u $USER -H cp config/secrets.yml.example $CONFIG/secrets.yml && \
    sudo -u $USER -H cp config/database.yml.postgresql $CONFIG/database.yml && \
    sudo -u $USER -H cp config/initializers/rack_attack.rb.example $CONFIG/rack_attack.rb && \
    sudo -u $USER -H ln -s $CONFIG/* config && \
    sudo -u $USER -H mv config/rack_attack.rb config/initializers && \
    sed --in-place "s/# user:.*/user: $USER/" config/gitlab.yml && \
    sed --in-place "s/host: localhost/host: $DOMAIN/" config/gitlab.yml && \
    sed --in-place "s:/home/git/repositories:$DATADIR/repo:" config/gitlab.yml && \
    sed --in-place "s:/home/git:/home/$USER:g" config/unicorn.rb && \
    sed --in-place "s/YOUR_SERVER_FQDN/$DOMAIN/" lib/support/nginx/gitlab

# Move log dir to /var/log data volume mount point
RUN mv /home/$USER/gitlab/log /var/log/gitlab && \
    sudo -u $USER -H ln -s /var/log/gitlab /home/$USER/gitlab/log

# Set permissions
RUN cd /home/$USER/gitlab && \
    chmod o-rwx config/database.yml && \
    chmod 0600 config/secrets.yml && \
    chown -R $USER log/ && \
    chown -R $USER tmp/ && \
    chmod -R u+rwX,go-w log/ && \
    chmod -R u+rwX tmp/ && \
    chmod -R u+rwX tmp/pids/ && \
    chmod -R u+rwX tmp/sockets/ && \
    chmod -R u+rwX builds/ && \
    chmod -R u+rwX shared/artifacts/ && \
    chmod -R ug+rwX shared/pages/ && \
    # set repo permissions
    chmod -R ug+rwX,o-rwx $DATADIR/repo && \
    chmod -R ug-s $DATADIR/repo && \
    find $DATADIR/repo -type d -print0 | sudo xargs -0 chmod g+s && \
    # create uploads dir
    sudo -u $USER -H mkdir public/uploads && \
    chmod 0700 public/uploads

# Install bundler
RUN cd /home/$USER/gitlab && \
    gem install bundler --no-ri --no-rdoc

# Maybe we should add these to the upstream Gemfile?
RUN cd /home/$USER/gitlab && \
    echo "gem 'bigdecimal'" >> Gemfile && \
    echo "gem 'tzinfo-data'" >> Gemfile

# use no deployment option first cause we changed gemfile
RUN cd /home/$USER/gitlab && \
    sudo -u $USER -H bundle install --jobs=$CPU_COUNT --no-deployment --path vendor/bundle --without development test mysql aws kerberos

# install gems
RUN cd /home/$USER/gitlab && \
    sudo -u $USER -H bundle install --jobs=$CPU_COUNT --deployment --without development test mysql aws kerberos

# compile GetText PO files
RUN cd /home/$USER/gitlab && \
    sudo -u $USER -H bundle exec rake gettext:pack RAILS_ENV=production && \
    sudo -u $USER -H bundle exec rake gettext:po_to_json RAILS_ENV=production

# Patch yarn - https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/14543/
COPY patches/yarn.patch /home/$USER/gitlab/
RUN sudo -u $USER -H /home/$USER/gitlab/yarn.patch

# compile assets
RUN cd /home/$USER/gitlab && \
    sudo -u $USER -H yarn install --production --pure-lockfile && \
    sudo -u $USER -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production

# create defaults file
RUN mkdir /etc/default && \
    touch /etc/default/gitlab && \
    # for entrypoint script
    echo "DOMAIN=$DOMAIN" >>/etc/default/gitlab && \
    echo "USER=$USER" >>/etc/default/gitlab && \
    echo "DIR=$DATADIR" >>/etc/default/gitlab && \
    echo "SOCKET=$SOCKET" >>/etc/default/gitlab && \
    # for gitlab init script
    echo "app_user=$USER" >>/etc/default/gitlab && \
    echo "shell_path=/bin/sh" >>/etc/default/gitlab

# Clean up
RUN rm -rf \
        /home/$USER/gitlab/node_modules \
        /home/$USER/gitlab/tmp \
        /home/$USER/gitlab/spec \
        /home/$USER/gitlab/doc \
        /home/$USER/gitlab/vendor/bundle/ruby/2.4.0/cache \
        /home/$USER/.cache/yarn && \
    apk del .build-deps sudo

VOLUME /var/opt/gitlab /var/log
