ARG CI_REGISTRY_IMAGE="registry.gitlab.com/gitlab-org/build/cng"
ARG TAG=latest
ARG FROM_IMAGE="$CI_REGISTRY_IMAGE/gitlab-rails-ee"
FROM ${FROM_IMAGE}:${TAG}

ARG GITLAB_USER=git

ENV SIDEKIQ_CONCURRENCY=25
ENV SIDEKIQ_TIMEOUT=4

# Install runtime deps. openssh-client is required so that SSH client binaries
# are present for repository mirroring.
RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-client

# Add scripts
COPY scripts/  /scripts/
RUN chown -R $GITLAB_USER:$GITLAB_USER /scripts

USER $GITLAB_USER:$GITLAB_USER

CMD /scripts/process-wrapper
