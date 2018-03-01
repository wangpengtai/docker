#!/bin/bash
declare -a nightly_builds=( gitlab-rails gitlab-unicorn gitaly gitlab-sidekiq )

function _containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

function is_nightly(){
  [ -n "$NIGHTLY" ] && $(_containsElement $CI_JOB_NAME ${nightly_builds[@]})
}

function is_master(){
  [ "$CI_COMMIT_REF_NAME" == "master" ]
}

function needs_build(){
  is_nightly || ! $(docker pull "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION" > /dev/null);
}

function build_if_needed(){
  if needs_build; then
    if [ -n "$BASE_IMAGE" ]; then
      docker pull $BASE_IMAGE
    fi

    DOCKER_ARGS=( "$@" )
    CACHE_IMAGE="$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CI_COMMIT_REF_SLUG"
    if ! $(docker pull $CACHE_IMAGE > /dev/null); then
      CACHE_IMAGE="$CI_REGISTRY_IMAGE/$CI_JOB_NAME:latest"
      docker pull $CACHE_IMAGE || true
    fi

    cd $CI_JOB_NAME

    docker build -t "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION" "${DOCKER_ARGS[@]}" --cache-from $CACHE_IMAGE .
    # Push new image
    docker push "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION"

    # Create a tag based on Branch/Tag name for easy reference
    docker tag "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION" "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CI_COMMIT_REF_SLUG"
    docker push "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CI_COMMIT_REF_SLUG"
  fi
}

function push_latest(){
  docker tag "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION" "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:latest"
  docker push "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:latest"
}

function get_version(){
  git ls-tree HEAD -- $1 | awk '{ print $3 }'
}

function get_target_version(){
  get_version $CI_JOB_NAME
}

function push_if_master(){
  if is_master; then
    push_latest
  fi
}
