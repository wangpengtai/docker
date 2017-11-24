ARG TAG=latest
FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-rails:${TAG}

ARG BUILD_DIR=/tmp/build

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

COPY unicorn/scripts/ /scripts
COPY unicorn/unicorn.rb /home/git/gitlab/config/unicorn.rb

CMD /scripts/process-wrapper
