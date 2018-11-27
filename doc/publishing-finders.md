# Publishing finders from a Rummager rake task

Rummager is currently used to publish two specific finders which do
not fit the standard specialist document finder pattern. These are:

- [Advanced search](advanced-search)
- Find EU Exit guidance for business (currently in development)

The configuration for these finders can be found in YAML files in 
the `config/` directory. These config files are a YAML representation
of a content item.  
The rake task 

```
DOCUMENT_FINDER_CONFIG=<finder-config-file-path> publishing_api:publish_document_finder
``` 

is used to present the finders to the publishing API.  

**NOTE:** The `find-eu-exit-guidance-business` finder config is overwritten by a
[shared definition in the govuk-app-deployment-secrets repo](https://github.com/alphagov/govuk-app-deployment-secrets/blob/master/shared_config/find-eu-exit-guidance-business.yml), the file committed to the
Rummager repo is a development copy.
