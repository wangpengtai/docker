ARG TAG=latest
FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-rails:${TAG}

ARG BUILD_DIR=/tmp/build
ARG DATADIR=/var/opt/gitlab
ARG CONFIG=$DATADIR/config/gitlab
ARG GITLAB_USER=git

# install build deps
RUN apk add --no-cache --virtual .build-deps \
        cmake g++ gcc linux-headers make go && \
        mkdir -p ${BUILD_DIR}

# Build Workhorse
RUN cd ${BUILD_DIR} && \
    WORKHORSE_VERSION=$(cat /home/git/gitlab/GITLAB_WORKHORSE_VERSION) && \
    curl -o workhorse.tar.bz2 https://gitlab.com/gitlab-org/gitlab-workhorse/repository/v${WORKHORSE_VERSION}/archive.tar.bz2 && \
    tar -xjf workhorse.tar.bz2 && \
    rm workhorse.tar.bz2 && \
    cd gitlab-workhorse-* && \
    make install && \
    cd

RUN rm -rf ${BUILD_DIR} && \
    apk del .build-deps

USER $GITLAB_USER:$GITLAB_USER

COPY scripts/ /scripts
COPY unicorn.rb ${CONFIG}/unicorn.rb

RUN cd /home/${GITLAB_USER}/gitlab && \
    ln -s ${CONFIG}/unicorn.rb config/unicorn.rb

ENV GITALY_FEATURE_DEFAULT_ON=1

CMD /scripts/process-wrapper

HEALTHCHECK --interval=30s --timeout=30s --retries=5 \
CMD /scripts/healthcheck
