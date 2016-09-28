---
title: Health check
---

As we work on rummager we want some objective metrics of the performance of search. That's what the health check is for.

To run it first download the healthcheck data:

$ ./bin/health_check -d

Then run against your chosen indices:

$ ./bin/health_check

Against remote:

$ ./bin/health_check -j "https://www.gov.uk/api/search.json"

Against development:

$ ./bin/health_check -j "http://www.dev.gov.uk/api/search.json"
