#!/bin/bash -x
bundle install --path "${HOME}/bundles/${JOB_NAME}"
RAILS_ENV=test bundle exec rake --trace
