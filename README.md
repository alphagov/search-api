# Rummager

## Specifying the location of the Slimmer asset host

Set the `SLIMMER_ASSET_HOST` environment variable, e.g. `SLIMMER_ASSET_HOST=http://static.dev bundle exec rackup`.  If you're using [pow](http://pow.cx/) then you can set this environment variable in .powrc (which is gitignored).

## Installing Solr

You can install solr using Homebrew on a Mac.

    $ brew install solr

## Starting Solr

Our solr config lives in the `alphagov/puppet` repository and is currently configured to expect config files to live in `/etc/solr` and data to live in `/var/solr`.  The simplest way to achieve this is to symlink them manually.

    $ export ALPHAGOV_PUPPET_PATH=/path/to/puppet
    $ sudo ln -s $ALPHAGOV_PUPPET_PATH/modules/solr/files/etc/solr /etc/solr
    $ sudo ln -s $ALPHAGOV_PUPPET_PATH/modules/solr/files/var/solr /var/solr
    $ solr $ALPHAGOV_PUPPET_PATH/modules/solr/files

## Manually indexing documents

    $ curl -v -XPOST -H"Content-Type: application/json" -d'{"title":"document title", "link":"http://example.com"}' http://rummager.dev/documents
    $ curl -v -XPOST -H"Content-Type: application/json" http://rummager.dev/commit

## Document format

    {
      title: "TITLE",
      description: "DESCRIPTION",
      format: "NAME OF FORMAT",
      link: "http://URL OR /PATH",
      indexable_content: "TEXT",
      additional_links: [ // OPTIONAL
        {title: "LINK TITLE", link: "http://URL OR /PATH"},
        // more links ...
      ]
    }

## Using the secondary results feature for Whitehall

First you need to enable it in the `feature_flags.yml` file to search for Whitehall "specialist guidance":

    development:
      use_secondary_solr_index: true
      secondary_solr_param_filter: "specialist_guidance"

Then a secondary Rummager needs to be run with the following configuration in `solr.yml`:

    development:
      :server: localhost
      :path: "/solr/whitehall-rummager"
      :port: 8983

and the following configuration in `router.yml`:

    :path_prefix: "/government"

Then set `RUMMAGER_HOST` to the hostname and port of the new instance when running the Rake task in whitehall:

    RUMMAGER_HOST=http://127.0.0.1:PORT bundle exec rake rummager:index

After the indexing you can stop the new instance as the secondary results will work on the regular Rummager.
