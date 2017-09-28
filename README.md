### Gitlab Rails Community Edition Docker Image
Based on Alpine Linux official image.
Built from source using Gitlab official source installation instructions with a
bunch of Alpine specific fixes.
This only contains the Rails code of GitLab, nothing else. It is intended to be
used as the foundation for other services, like Unicorn or Sidekiq.

Volumes:
- /var/opt/gitlab - config, repositories and postgres data
- /var/log - logs
