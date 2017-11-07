ARG TAG=latest
FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-rails:${TAG}

COPY unicorn.rb /home/git/gitlab/config/unicorn.rb

ENTRYPOINT /home/git/gitlab/bin/bundle exec unicorn \
              -E production \
              -c /home/git/gitlab/config/unicorn.rb \
              /home/git/gitlab/config.ru
