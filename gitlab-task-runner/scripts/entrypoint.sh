#!/bin/bash

set -e
/scripts/set-config "${CONFIG_TEMPLATE_DIRECTORY}" "${CONFIG_DIRECTORY:=$CONFIG_TEMPLATE_DIRECTORY}"

cd /home/git/gitlab;
echo "Attempting to run rake task $@";

bundle exec rake $@;
