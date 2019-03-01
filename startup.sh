#!/bin/bash

bundle install
bundle exec mr-sparkle --force-polling -- -p 3009
