# Publishing finders from a Rummager rake task

Rummager is currently used to publish two specific finders which do
not fit the standard specialist document finder pattern. These are:

- [Advanced search](advanced-search)
- Find EU Exit guidance for business (currently in development)

The configuration for these finders can be found in YAML files in
the `config/` directory. These config files are a YAML representation
of a content item.  

This rake task is used to present the advanced-search finder to the publishing API:

```
DOCUMENT_FINDER_CONFIG=<finder-config-file-path> publishing_api:publish_document_finder
```

This rake task is used to present the Find EU Exit guidance for business finder to the
publishing API:

```
publishing_api:publish_eu_exit_business_finder
```

**Note:** Both rake tasks `publishing_api:publish_document_finder` and `publishing_api:publish_eu_exit_business_finder`
are to be deprecated.

For new finder content items, use the rake task `publishing_api:publish_finder`. For example:

```
FINDER_CONFIG=news_and_communications.yml EMAIL_SIGNUP_CONFIG=news_and_communications_email_signup.yml publishing_api:publish_finder
```

**NOTE:** The `find-eu-exit-guidance-business` finder config is overwritten by a
[shared definition in the govuk-app-deployment-secrets repo](https://github.com/alphagov/govuk-app-deployment-secrets/blob/master/shared_config/find-eu-exit-guidance-business.yml), the file committed to the
Rummager repo is a development copy.
