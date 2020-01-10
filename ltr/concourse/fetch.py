import os, requests, sys, time

govuk_environment = os.environ["GOVUK_ENVIRONMENT"]

SEARCH_API_TRAIN_URL = f"https://search-api.{govuk_environment}.govuk.digital/ltr/train"
SEARCH_API_DATA_URL = (
    f"https://search-api.{govuk_environment}.govuk.digital/ltr/latest-data"
)

session = requests.Session()
session.headers.update(HEADERS)

# despite the name this does both http and https
session.mount('https://', requests.adapters.HTTPAdapter(max_retries=5))

trigger = session.post(SEARCH_API_TRAIN_URL)
print(f"POST ({trigger.status_code}) {trigger.text}", file=sys.stderr)
# POST isn't idempotent, so it's possible we could trigger the job but
# fail to receive the response and then re-trigger it.
if trigger.status_code not in [202, 409]:
    sys.exit(1)

status_code = 202
while status_code == 202:
    check = session.get(SEARCH_API_TRAIN_URL)
    print(f"GET ({check.status_code}) {check.text}", file=sys.stderr)
    status_code = check.status_code
    time.sleep(60)

if status_code != 200:
    sys.exit(1)

result = session.get(SEARCH_API_DATA_URL)
print(f"GET ({result.status_code}) {result.text}", file=sys.stderr)
if result.status_code != 200:
    sys.exit(1)

print(result.text)

print("done", file=sys.stderr)