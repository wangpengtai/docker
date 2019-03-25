ARG CI_REGISTRY_IMAGE="registry.gitlab.com/gitlab-org/build/cng"
ARG TAG=latest
ARG FROM_IMAGE="$CI_REGISTRY_IMAGE/git-base"

FROM ${FROM_IMAGE}:${TAG}

ARG BUILD_DIR=/tmp/build
ARG GEI_VERSION="1.0.0"

RUN buildDeps=' \
  libicu-dev \
  make' \
  && apt-get update \
  && apt-get install -y --no-install-recommends $buildDeps \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p ${BUILD_DIR}

RUN cd ${BUILD_DIR} \
  && curl -s "https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer/-/archive/v${GEI_VERSION}/gitlab-elasticsearch-indexer-v${GEI_VERSION}.tar.gz" | tar zx \
  && cd "${BUILD_DIR}/gitlab-elasticsearch-indexer-v${GEI_VERSION}" \
  && make \
  && make install \
  && cd / \
  && rm -rf "${BUILD_DIR}"
