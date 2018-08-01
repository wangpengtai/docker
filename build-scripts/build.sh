#!/bin/bash
declare -a nightly_builds=( gitlab-rails-ee gitlab-rails-ce gitlab-unicorn-ce gitlab-unicorn-ee gitaly gitlab-sidekiq-ee gitlab-sidekiq-ce gitlab-workhorse-ce gitlab-workhorse-ee )

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
    export BUILDING_IMAGE="true"
    if [ -n "$BASE_IMAGE" ]; then
      docker pull $BASE_IMAGE
    fi

    DOCKER_ARGS=( "$@" )
    CACHE_IMAGE="$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CI_COMMIT_REF_SLUG"
    if ! $(docker pull $CACHE_IMAGE > /dev/null); then
      CACHE_IMAGE="$CI_REGISTRY_IMAGE/$CI_JOB_NAME:latest"
      docker pull $CACHE_IMAGE || true
    fi

    cd $(get_trimmed_job_name)

    docker build -t "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION" "${DOCKER_ARGS[@]}" --cache-from $CACHE_IMAGE .
    # Push new image
    docker push "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION"

    # Create a tag based on Branch/Tag name for easy reference
    tag_and_push $CI_COMMIT_REF_SLUG
  fi
}

function tag_and_push(){
  docker tag "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION" "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$1"
  docker push "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$1"
}

function push_latest(){
  tag_and_push "latest"
}

function get_version(){
  git ls-tree HEAD -- $1 | awk '{ print $3 }'
}

function get_target_version(){
  get_version $(get_trimmed_job_name)
}

function get_trimmed_job_name(){
  trim_edition $CI_JOB_NAME
}

function trim_edition(){
  echo $1 | sed -e "s/-.e$//"
}

function trim_tag(){
  echo $(trim_edition $1) | sed -e "s/^v//"
}

function push_if_master(){
  if is_master; then
    if [ -z "$1" ] || [ "$1" == "master" ]; then
      push_latest
    else
      tag_and_push $(trim_edition $1)
    fi
  fi
}
