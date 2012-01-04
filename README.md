# Rummager

## Specifying the location of the Slimmer asset host

Set the `SLIMMER_ASSET_HOST` environment variable, e.g. `SLIMMER_ASSET_HOST=http://static.dev bundle exec rackup`.  If you're using [pow](http://pow.cx/) then you can set this environment variable in .powrc (which is gitignored).

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

