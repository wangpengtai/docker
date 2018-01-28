ARG TAG=latest

FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-rails:${TAG}
ARG GITLAB_USER=git

ENV SIDEKIQ_CONCURRENCY=25
ENV SIDEKIQ_TIMEOUT=4

# Add scripts
COPY scripts/  /scripts/
RUN chown -R $GITLAB_USER:$GITLAB_USER /scripts

USER $GITLAB_USER:$GITLAB_USER

CMD /scripts/process-wrapper
