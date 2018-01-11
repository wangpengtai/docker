#!/bin/bash
function build(){
  DOCKER_ARGS=( "$@" )
  CACHE_IMAGE="$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CI_COMMIT_REF_SLUG"
  if ! $(docker pull $CACHE_IMAGE > /dev/null); then
    CACHE_IMAGE="$CI_REGISTRY_IMAGE/$CI_JOB_NAME:latest"
    docker pull $CACHE_IMAGE || true
  fi

  cd $WORKDIR

  echo "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERS"
  docker build -t "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION" "${DOCKER_ARGS[@]}" --cache-from $CACHE_IMAGE .
  # Push new image
  docker push "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION"

  # Create a tag based on Branch/Tag name for easy reference
  docker tag "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION" "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CI_COMMIT_REF_SLUG"
  docker push "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CI_COMMIT_REF_SLUG"
}

function push_latest(){
  docker tag "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION" "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:latest"
  docker push "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:latest"
}
