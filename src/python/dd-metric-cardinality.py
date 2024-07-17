# from datadog import initialize, api

import os
import requests

options = {
    "api_key": os.environ['DATADOG_API_KEY'],
    "app_key": os.environ['DATADOG_APP_KEY'],
}

def get_metric_cardinality(metric_name):
    url = f"https://api.datadoghq.com/api/v2/metrics/{metric_name}/estimate?filter[groups]=host,aws"
    response = requests.get(url, headers={"DD-API-KEY": options['api_key'], "DD-APPLICATION-KEY": options['app_key']})
    return response.json()

print(get_metric_cardinality('app.users.browser'))

# initialize(**options)

# api.Metric

# https://docs.datadoghq.com/api/latest/metrics/#tag-configuration-cardinality-estimator
# https://api.datadoghq.com/api/v2/metrics/{metric_name}/estimate
