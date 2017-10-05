FROM gitlab-rails:10-0-stable-base-ee

COPY unicorn.rb /home/git/gitlab/config/unicorn.rb

ENTRYPOINT /home/git/gitlab/bin/bundle exec unicorn \
              -E production \
              -c /home/git/gitlab/config/unicorn.rb \
              /home/git/gitlab/config.ru
