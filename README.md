# Rummager

Rummager is now primarily based on ElasticSearch.

## Get started

Run the application with `./startup.sh` this uses shotgun/thin.

To create indices, or to update them to the latest index settings, run:

    RUMMAGER_INDEX=all bundle exec rake rummager:migrate_index

If you have indices from a Rummager instance before aliased indices, run:

    RUMMAGER_INDEX=all bundle exec rake rummager:migrate_from_unaliased_index

If you don't know which of these you need to run, try running the first one; it
will fail safely with an error if you have an unmigrated index.

## Indexing GOV.UK content

Since search indexing happens through Panopticon's single registration API,
you'll need to have both Panopticon and Rummager running. By default, Panopticon
will not try to index search content in development mode, so you'll need to pass
an extra environment variable to it.

If you have [Bowler](https://github.com/JordanHatch/bowler) installed, you can
set these both running with a single command from the `development` repository:

    UPDATE_SEARCH=1 bowl panopticon rummager

The next stage is to register content from the applications you want. For
example:

  * Business Support Finder
  * Calendars
  * Licence Finder
  * Publisher
  * Smart Answers
  * Trade Tariff

To re-register content for a single application, go to its directory and run:

    bundle exec rake panopticon:register

To register content for all the applications, go to the `replication` directory
in the `development` project and run:

    ./rebuild-search-local.sh

To rebuild from the Whitehall application, follow the [instructions in the
app](https://github.com/alphagov/whitehall#getting-search-running-locally).
