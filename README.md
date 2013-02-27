# Rummager

Rummager is now primarily based on ElasticSearch.

## Get started

Run the application with `./startup.sh` this uses unicorn so your application
changes will not be loaded unless you restart. This is because unicorn is more
reliable than shotgun.

Generate your index with:

    bundle exec rake rummager:put_mapping

which will generate the index as specified by the `primary` group in `backends.yml`.

To build an alternative index, pass the backend name via an environment variable:

    BACKEND=secondary bundle exec rake rummager:put_mapping

If you want to set up the mainstream, detailed and Inside Government indexes in
one go, use the command:

    bundle exec rake rummager:put_all_mappings

## Indexing GOV.UK content

Since search indexing happens through Panopticon's single registration API,
you'll need to have both Panopticon and Rummager running. By default, Panopticon
will not try to index search content in development mode, so you'll need to pass
an extra parameter to it.

If you have [Bowler](https://github.com/JordanHatch/bowler) installed, you can
set these both running with a single command from the `development` repository:

    UPDATE_SEARCH=1 bowl panopticon rummager

The next stage is to register content from all the applications. These are:

  * calendars
  * smartanswers
  * licencefinder
  * publisher

To re-register content for a single application, go to its directory and run:

    bundle exec rake panopticon:register

To register content for all the applications, go to the `replication` directory
in the `development` project and run:

    ./rebuild-search-local.sh

This should take about four minutes.
