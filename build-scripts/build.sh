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

    pushd $(get_trimmed_job_name)
    echo "PWD is" $(pwd)
    echo "contents are" $(ls)
    echo "Docker version is" $(docker --version)

    if [ -x renderDockerfile ]; then
      ./renderDockerfile
    fi

    echo docker build --build-arg CI_REGISTRY_IMAGE=$CI_REGISTRY_IMAGE -t "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION" "${DOCKER_ARGS[@]}" --cache-from $CACHE_IMAGE .

    docker build --build-arg CI_REGISTRY_IMAGE=$CI_REGISTRY_IMAGE -t "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION" "${DOCKER_ARGS[@]}" --cache-from $CACHE_IMAGE .
    # Push new image
    docker push "$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CONTAINER_VERSION"

    # Create a tag based on Branch/Tag name for easy reference
    tag_and_push $CI_COMMIT_REF_SLUG
    popd
  fi
  echo "$CI_JOB_NAME:$CONTAINER_VERSION" > "artifacts/$CI_JOB_NAME.txt"
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

function is_tag(){
  [ -n "${CI_COMMIT_TAG}" ] || [ -n "${GITLAB_TAG}" ]
}

function trim_edition(){
  echo $1 | sed -e "s/-.e$//"
}

function trim_tag(){
  echo $(trim_edition $1) | sed -e "s/^v//"
}

function push_if_master_or_tag(){

  # For tag pipelines, nothing needs to be done on gitlab.com project. Images
  # will be built, and copied to .com registry as part of the release. However,
  # this check is done here intentionally, and not at build time (which
  # involves pushing CONTAINER_VERSION, CI_COMMIT_REF_SLUG tags also) because
  # we may not be syncing build images, but only the user facing images.
  if [ "$CI_REGISTRY" == "registry.gitlab.com" ] && [ -n "$CI_COMMIT_TAG" ]; then
          exit 0
  fi

  if is_master || is_tag; then
    if [ -z "$1" ] || [ "$1" == "master" ]; then
      push_latest
    else
      local edition="$1"
      if is_tag; then
        edition=$(trim_edition $edition)
      fi
      tag_and_push $edition
      echo "$CI_JOB_NAME:$edition" > "artifacts/$CI_JOB_NAME.txt"
    fi
  fi
}
