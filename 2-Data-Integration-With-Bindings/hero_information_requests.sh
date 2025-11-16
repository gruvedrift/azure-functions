#!/bin/bash

set -e

FUNCTION_URL=$(cd terraform && terraform output -raw function_app_url)

# Query some heroes:
curl "$FUNCTION_URL/api/analytics/hero-information/1"
curl "$FUNCTION_URL/api/analytics/hero-information/2"
curl "$FUNCTION_URL/api/analytics/hero-information/3"
curl "$FUNCTION_URL/api/analytics/hero-information/5"
curl "$FUNCTION_URL/api/analytics/hero-information/6"
curl "$FUNCTION_URL/api/analytics/hero-information/5"
curl "$FUNCTION_URL/api/analytics/hero-information/5"
curl "$FUNCTION_URL/api/analytics/hero-information/6"
curl "$FUNCTION_URL/api/analytics/hero-information/7"
curl "$FUNCTION_URL/api/analytics/hero-information/4"

