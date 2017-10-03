### Gitlab Enterprise Edition Docker Images

Based on the [Alpine Linux](https://alpinelinux.org/) [official image](https://hub.docker.com/_/alpine/).

Built using [the official source installation instructions](http://docs.gitlab.com/ee/install/installation.html) with some Alpine specific fixes.

Each directory contains the `Dockerfile` for a specific component of the
infrastructure needed to run GitLab.

* [rails](/rails) - The Rails code needed for both API and web.
* [unicorn](/unicorn) - The Unicorn container that exposes Rails.
