#!/bin/bash

usage()
{
cat << EOF
Usage: $0 [options]

Run a development server.

OPTIONS:
   -h       Show this message
   -n       Skip bundle installation


EOF
}

while getopts "hn" OPTION
do
  case $OPTION in
    h )
      usage
      exit 1
      ;;
    n )
      # Load a custom SSH config file if given
      NO_INSTALL=1
      ;;
  esac
done
shift $(($OPTIND-1))

if [[ -z $NO_INSTALL ]]; then
  bundle install
fi
bundle exec mr-sparkle --force-polling -- -p 3009
