# Rummager

## Specifying the location of the Slimmer asset host

Set the `SLIMMER_ASSET_HOST` environment variable, e.g. `SLIMMER_ASSET_HOST=http://static.dev bundle exec rackup`.  If you're using [pow](http://pow.cx/) then you can set this environment variable in .powrc (which is gitignored).

## Installing Solr

You can install solr using Homebrew on a Mac.

    $ brew install solr

## Starting Solr

Our solr config lives in alphagov-deployment and is currently configured to expect config files to live in /etc/solr and data to live in /var/solr.  The simplest way to achieve this is to symlink them manually.

    $ export ALPHAGOV_DEPLOY_PATH=/path/to/alphagov-deployment
    $ sudo ln -s $ALPHAGOV_DEPLOY_PATH/alphagov-puppet/puppet/modules/solr/files/etc/solr /etc/solr
    $ sudo ln -s $ALPHAGOV_DEPLOY_PATH/alphagov-puppet/puppet/modules/solr/files/var/solr /var/solr
    $ solr $ALPHAGOV_DEPLOY_PATH/alphagov-puppet/puppet/modules/solr/files

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
