ARG TAG=latest
FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-rails:${TAG}
ENV SIDEKIQ_CONCURRENCY=25
ENV SIDEKIQ_TIMEOUT=4

CMD /home/git/gitlab/bin/bundle exec sidekiq \
              -r /home/git/gitlab \
              -e production \
              -c $SIDEKIQ_CONCURRENCY \
              -t $SIDEKIQ_TIMEOUT \
              -C /home/git/gitlab/config/sidekiq_queues.yml
