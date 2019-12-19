# Publishing finders

Search API is currently used to publish some finders which do not fit
the standard specialist document finder pattern. These are:

- Advanced search, available at the path `/search/advanced`
- Find EU Exit guidance for business (currently in development)

The configuration for the EU Exit business finder can be found in YAML files in
the `config/` directory. These config files are a YAML representation
of a content item.

This rake task is used to present the Find EU Exit guidance for business finder to the
publishing API:

```
publishing_api:publish_eu_exit_business_finder
```

For new finder content items, use the rake task `publishing_api:publish_finder`. For example:

```
FINDER_CONFIG=news_and_communications.yml EMAIL_SIGNUP_CONFIG=news_and_communications_email_signup.yml publishing_api:publish_finder
```
