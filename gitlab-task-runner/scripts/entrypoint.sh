#!/bin/bash

cd /home/git/gitlab;
echo "Attempting to run rake task $@";

bundle exec rake $@;
