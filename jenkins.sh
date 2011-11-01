#!/bin/bash -x
bundle install --path "${HOME}/bundles/${JOB_NAME}"
RACK_ENV=test bundle exec rake ci:setup:testunit test --trace
