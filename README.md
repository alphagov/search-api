# Rummager

Rummager is now primarily based on ElasticSearch.

## Get started

Generate your index with:

    rake rummager:create_index

which will generate the index as specified by the `primary` group in `backends.yml`.

To build an alternative index, pass the backend name via an environment variable:

    BACKEND=secondary rake rummager:create_index

## Indexing GOV.UK content

Use the:

    rake panopticon:register

task in the [Publisher](https://github.com/alphagov/publisher) project.
