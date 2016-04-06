#!/bin/bash -x

set -e

# Try to merge master into the current branch, and abort if it doesn't exit
# cleanly (ie there are conflicts). This will be a noop if the current branch
# is master.
git merge --no-commit origin/master || git merge --abort

bundle install --path "${HOME}/bundles/${JOB_NAME}"

# DELETE STATIC SYMLINKS AND RECONNECT...
for d in images javascripts templates stylesheets; do
  rm -f public/$d
  ln -s ../../../Static/workspace/public/$d public/
done

# Lint changes introduced in this branch, but not for master
if [[ ${GIT_BRANCH} != "origin/master" ]]; then
  bundle exec govuk-lint-ruby \
    --diff \
    --cached \
    --format html --out rubocop-${GIT_COMMIT}.html \
    --format clang \
    app test lib
fi

USE_SIMPLECOV=true RACK_ENV=test bundle exec rake ci:setup:minitest test --trace
