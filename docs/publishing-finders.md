# Publishing finders

Search API is currently used to publish some finders which do not fit
the standard specialist document finder pattern. These are:

For new finder content items, use the rake task `publishing_api:publish_finder`. For example:

```
FINDER_CONFIG=news_and_communications.yml EMAIL_SIGNUP_CONFIG=news_and_communications_email_signup.yml publishing_api:publish_finder
```
