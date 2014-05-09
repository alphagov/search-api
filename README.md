# Rummager

Rummager is now primarily based on elasticsearch.

## Get started

Install [elasticsearch 0.20](http://www.elasticsearch.org/downloads/0-20-6/).
Rummager doesn't work with 0.90.

Run the application with `./startup.sh` this uses shotgun/thin.

To create indices, or to update them to the latest index settings, run:

    RUMMAGER_INDEX=all bundle exec rake rummager:migrate_index

If you have indices from a Rummager instance before aliased indices, run:

    RUMMAGER_INDEX=all bundle exec rake rummager:migrate_from_unaliased_index

If you don't know which of these you need to run, try running the first one; it
will fail safely with an error if you have an unmigrated index.

Rummager has an asynchronous mode, disabled in development by default, that
posts documents to a queue to be indexed later by a worker. To run this in
development, you need to run both of these commands:

    ENABLE_QUEUE=1 ./startup.sh
    bundle exec rake jobs:work

## Indexing GOV.UK content

### Memory requirements

In order to build the search index on a VM, you'll need to ensure that your VM
has sufficient memory: 4Gb is probably a good amount; with 2Gb, the indexing
process has a tendency to get killed by the out of memory killer.  Do this by
adding a `Vagrantfile.localconfig` to the same directory as your Vagrantfile:

    $ cat ./Vagrantfile.localconfig
    config.vm.provider :virtualbox do |vm|
      vm.customize [ "modifyvm", :id, "--memory", "4096", "--cpus", "2" ]
    end

It's probably a good idea to give elasticsearch more memory, too, since that
will make indexing faster, and also avoid risk of elasticsearch running out of
memory and killing itself.  Do this by editing
/etc/init/elasticsearch-govuk-development.conf to include the line:

    env ES_HEAP_SIZE="1024m"

Restart the VM (eg, with `vagrant reload`) after making these changes.

### Popularity information

The gov.uk search uses page popularity information extracted from Google
Analytics as one of the factors in weighting search results.  This is extracted
from Google Analytics by the search-analytics project, which produces a dump
file suitable for loading into an elasticsearch index using rummager's
`bulk_load` tool.  This should be loaded into the `page-traffic` index.

In many cases, you should be able to fetch the `page-traffic.dump` data from
preview.
FIXME: describe how to get hold of a copy of `page-traffic.dump` data from
preview, once jobs are set up to regularly extract this.  This will be
implemented as part of
https://www.pivotaltracker.com/s/projects/1010882/stories/70737424

The [search-analytics project
README](https://github.com/alphagov/search-analytics) describes how to set up
and run the extraction of page traffic information from Google Analytics, if
you need to get the data yourself.

Once you have the popularity data in a file named `page-traffic.dump`, load it
into elasticsearch using:

    bundle exec bin/bulk_load page-traffic < page-traffic.dump

The popularity information won't affect search results until an index migration
is run after populating the page-traffic index. As part of the migration, the
popularity for each document will be computed from the page-traffic index and
merged into the documents. To do this, run:

    RUMMAGER_INDEX=all bundle exec rake rummager:migrate_index

### Indexing panopticon content

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

## Adding a new index

To add a new index to Rummager, you'll first need to add it to the list of index
names Rummager knows about in [`elasticsearch.yml`](elasticsearch.yml). For
instance, you might change it to:

    index_names: ["mainstream", "detailed", "government", "my_new_index"]

To create the index, you'll need to run:

    RUMMAGER_INDEX=my_new_index bundle exec rake rummager:migrate_index

This task will fail if you've already created an index with this name, as
Rummager can't add an alias that is the name of an existing index. In this case,
you'll either need to delete your existing index or, if you want to keep its
contents, run:

    RUMMAGER_INDEX=my_new_index bundle exec rake rummager:migrate_from_unaliased_index

## Health check

As we work on rummager we want some objective metrics of the performance of search. That's what the health check is for.

To run it first download the healthcheck data:

$ ./bin/health_check -d

Then run against your chosen indices:

$ ./bin/health_check government mainstream

By default it will run against the local search instance. You can run against a remote search service using the --json or --html options.
