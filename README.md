### Gitlab Enterprise Edition Docker Images

Based on the [Alpine Linux](https://alpinelinux.org/) [official image](https://hub.docker.com/_/alpine/).

Built using [the official source installation instructions](http://docs.gitlab.com/ee/install/installation.html) with some Alpine specific fixes.

Each directory contains the `Dockerfile` for a specific component of the
infrastructure needed to run GitLab.

* [rails](/rails) - The Rails code needed for both API and web.
* [unicorn](/unicorn) - The Unicorn container that exposes Rails.

### Dev environment using Docker Compose

A dev test environment is provided with docker-compose that includes running the gitlab omnibus container to fill in the gaps that this repo in missing
in terms of services.

Currently the containers do not wait for their dependant services to become available, so to run the environment:

```bash
docker-compose up omnibus
# Wait for the omnibus to start and finish reconfigure
docker-compose up
# To bring up the other containers
```
