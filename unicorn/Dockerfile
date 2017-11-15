ARG TAG=latest
FROM registry.gitlab.com/gitlab-org/build/cng/gitlab-rails:${TAG}

COPY unicorn.rb /var/cache/omnibus/src/gitlab-rails/config/unicorn.rb

CMD /var/cache/omnibus/src/gitlab-rails/bin/bundle exec unicorn \
              -E production \
              -c /var/cache/omnibus/src/gitlab-rails/config/unicorn.rb \
              /var/cache/omnibus/src/gitlab-rails/config.ru
