#!/bin/bash -x
bundle install --path "${HOME}/bundles/${JOB_NAME}"

# DELETE STATIC SYMLINKS AND RECONNECT...
for d in images javascripts templates stylesheets; do
  rm -f public/$d
  ln -s ../../../Static/workspace/public/$d public/
done

USE_SIMPLECOV=true RACK_ENV=test bundle exec rake ci:setup:testunit test --trace
