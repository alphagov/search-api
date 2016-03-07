# Schema definitions

This directory tree holds the schema definitions for our search indexes.
The purpose of the schema is to define:

 - which fields are allowed to be present in documents passed to the search
   indexer
 - how these fields should be processed at indexing time
 - how these fields should be searched at query time

The schema is used to produce the elasticsearch configuration for each index,
but is also used to control how the fields are processed before passing them to
elasticsearch, and after retrieving results from elasticsearch.

There are several "layers" of the schema; field types, which are used to define
the configuration for a named set of fields, which are then used to define a
set of document types, which are then used to make up the configuration for an
index.

## Field types

The `field_types.json` file contains a JSON object describing some "high-level"
named types which can be applied to fields in documents.  Each type is keyed by
the name of the type, and has the following properties:

 - `description`: a human-readable description of what the type is to be used
   for (this is essentially a comment field).

 - `es_config`: the elasticsearch configuration to be applied to fields using
   this type.

 - `multivalued`: (optional, default of `false`) - if true, the field is
   allowed to contain multiple values, and will be represented as an array when
   documents are being returned.

 - `children`: (optional) - if present, the field contains child fields (ie,
   the field values will be JSON objects containing the child fields).  This
   must be set to one of two values:

   - `named`: The definition of the field (see next section) must contain a
     `children` property, defining the allowed child fields.

   - `dynamic`: Arbitrary child fields will be accepted, but how they are
     handled will be configured dynamically according to the elasticsearch
     configuration.

## Field definitions

To keep things simple we require that for a field of a given name, the same
configuration must be used regardless of document type, or even search index
that the document is being placed in.

The `field_definitions.json` file describes what configuration should be used
for each named field; this single-point of configuration ensures that differing
configuration cannot be used for a single field name.

The file contains a JSON object in which the keys are the field names.  Each
value has the following properties:

 - `description`: a human-readable description of what type of data is expected
   to exist in the field.

 - `type`: one of the type values defined in the `field_types.json` file.

 - `children`: (only for fields for which the type had the `children` property
   set to `named`) the field definitions for the child fields.  These are in
   the same format as the top-level field definitions in the file (and could
   even be recursive).

## Document types

Documents in an elasticsearch index have a type, and each type may have very
different configuration.  We define a basic configuration which is used across
all document types, and additional configuration for each document type is then
merged with this.

The basic configuration is defined in a `base_document_type.json` file.
Document types are defined in the `document_types` directory, with the
additional configuration for each type being defined by a JSON file in that
directory.

The document type files contain JSON object with the following keys:

 - `fields`: An array of field names which are allowed in documents of this
   type.  The field names must be defined in the `field_definitions.json` file.

 - `expanded_search_result_fields`: DEPRECATED. Sets up field "expansion" for a
    field. This is used by the search result presenter to replace a raw value.

    For example:

    ```
    "expanded_search_result_fields": {
      "fault_type": [
        {
          "label": "Recall",
          "value": "recall"
        },
        {
          "label": "Non-urgent fault",
          "value": "non_urgent_fault"
        }
      ],
    ```

    Will return make the presenter replace the `fault_type` with value `recall`
    with the hash `{ "label": "Recall", "value": "recall" }`. This can be used
    when displaying the search results.

## Indexes

Indexes in elasticsearch are defined by files in the `indexes` directory.
These files contain a JSON object with the following keys:

 - `document_types`: An array of the names of the document types allowed in this index.

## Synonyms

Synonyms are defined in the `synonyms.yml` file.

Synonyms are specified in "lucene" syntax.  Each synonym group is represented
as comma separated lists of synonyms, and optionally a "=>" symbol.

If the => is provided, the left hand side contains a list of words which are
combined at search time into a group, and the right hand side contains the list
of words which are combined at index time into that same group.  ie, the left
hand side is the mapping applied to searches, and the right hand side is the
mapping applied to documents.

If there is no =>, the same group of words is used at index time as at
search time.

Some examples:

    foo, bar => baz

means "a search for 'foo' or 'bar' should return documents with 'baz' in them"

    foo => bar, baz

means "a search for 'foo' should return documents with 'bar' or 'baz' in them"

    foo, bar, baz

is the same as `foo, bar, baz => foo, bar, baz` and means "a search for
foo, bar or baz should return documents with any of them".

## Additional configuration

Additional configuration is defined in the `elasticsearch_schema.yml` and
`stems.yml` files.  This configuration is merged with the JSON configuration,
and then passed to elasticsearch directly.

The `old_synonyms.yml` contains a set of synonyms which were applied in an old,
and moderately broken, way.  This is kept separate from the `synonyms.yml` file
so that we can support and modify the lists for the new synonym approach
without changing things for the old approach.  Once we're happy with the new
approach, we'll delete the `old_synonyms.yml` file, and remove support for
using it.
