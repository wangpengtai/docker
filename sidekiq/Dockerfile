ARG TAG=latest
FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-rails:${TAG}
ENV SIDEKIQ_CONCURRENCY=25
ENV SIDEKIQ_TIMEOUT=4

# Add scripts
COPY scripts/  /scripts/

CMD /scripts/process-wrapper
