ARG CI_REGISTRY_IMAGE="registry.gitlab.com/gitlab-org/build/cng"
ARG TAG=latest
ARG FROM_IMAGE="$CI_REGISTRY_IMAGE/gitlab-go"

FROM ${FROM_IMAGE}:${TAG}

ARG BUILD_DIR=/tmp/build
ARG GITLAB_ELASTICSEARCH_INDEXER_VERSION="1.0.0"

RUN buildDeps=' \
  gcc \
  libicu-dev \
  make \
  pkg-config' \
  && apt-get update \
  && apt-get install -y --no-install-recommends $buildDeps \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p ${BUILD_DIR}

RUN cd ${BUILD_DIR} \
  && curl -s "https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer/-/archive/v${GITLAB_ELASTICSEARCH_INDEXER_VERSION}/gitlab-elasticsearch-indexer-v${GITLAB_ELASTICSEARCH_INDEXER_VERSION}.tar.gz" | tar zx \
  && cd "${BUILD_DIR}/gitlab-elasticsearch-indexer-v${GITLAB_ELASTICSEARCH_INDEXER_VERSION}" \
  && make \
  && make install \
  && cd / \
  && rm -rf "${BUILD_DIR}"
