#!/usr/bin/env bash
set -euo pipefail

rake page_traffic:load

SEARCH_INDEX=page-traffic rake search:clean
