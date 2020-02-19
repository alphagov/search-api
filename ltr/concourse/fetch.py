import os, requests, sys, time

govuk_environment = os.environ["GOVUK_ENVIRONMENT"]
bearer_token = os.environ["SEARCH_API_BEARER_TOKEN"]

SEARCH_API_TRAIN_URL = f"https://search-api.{govuk_environment}.govuk.digital/ltr/train"
SEARCH_API_DATA_URL = (
    f"https://search-api.{govuk_environment}.govuk.digital/ltr/latest-data"
)

session = requests.Session()
session.headers.update({"Authorization": f"Bearer {bearer_token}"})

# despite the name this does both http and https
session.mount("https://", requests.adapters.HTTPAdapter(max_retries=5))

trigger = session.post(SEARCH_API_TRAIN_URL)
print(f"POST ({trigger.status_code}) {trigger.text}", file=sys.stderr)
# POST isn't idempotent, so it's possible we could trigger the job but
# fail to receive the response and then re-trigger it.
if trigger.status_code not in [202, 409]:
    sys.exit(1)


def do_status_check():
    check = session.get(SEARCH_API_TRAIN_URL)
    print(f"GET ({check.status_code}) {check.text}", file=sys.stderr)
    return check.status_code

max_retries = 3
status_code = 202
while status_code == 202:
    status_code = do_status_check()
    # 401 could be a temporary auth faulure due to a signon hiccup
    if status_code == 401:
        retries = 0
        while status_code == 401 and retries < max_retries:
            time.sleep(20)
            retries += 1
            print(f"  (retrying {retries} / {max_retries})")
            status_code = do_status_check()
    time.sleep(60)

if status_code != 200:
    sys.exit(1)

result = session.get(SEARCH_API_DATA_URL)
print(f"GET ({result.status_code}) {result.text}", file=sys.stderr)
if result.status_code != 200:
    sys.exit(1)

print(result.text)

print("done", file=sys.stderr)
