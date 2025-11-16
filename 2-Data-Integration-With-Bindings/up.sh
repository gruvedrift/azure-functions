#!/bin/bash

set -e

cd ./terraform

echo "=== Stage 1: Provisioning Infrastructure ==="

terraform init
terraform fmt
terraform validate
terraform apply -auto-approve

FUNCTION_APP_NAME=$(terraform output --raw function_app_name)
FUNCTION_APP_URL=$(terraform output --raw function_app_url)
RESOURCE_GROUP_NAME=$(terraform output --raw resource_group_name)


echo ""
echo "=== Stage 2 Creating Deployment package for Azure Functions ==="

cd ../functions
zip deploy.zip function_app.py host.json requirements.txt .

echo ""
echo "=== Stage 3: Deploying Azure Functions package to Azure ==="
az functionapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $FUNCTION_APP_NAME \
  --src deploy.zip

echo ""
echo "=== Stage 4: Populating Container with Test Data ==="
sleep 10

echo ""
echo "Deployment complete!"
sleep 1


echo ""
echo "=== How to Test: === "
echo ""
echo "Test Cosmos DB Input Binding (Read Only):"
echo "  curl $FUNCTION_APP_URL/api/hero-information/1"

echo ""
echo "Test with Input + Output Bindings (Read & Archive):"
echo "  curl $FUNCTION_APP_URL/api/archive/hero-information/1"

echo ""
echo "Test with Input + Output Bindings + Service Bus:"
echo "  curl $FUNCTION_APP_URL/api/analytics/hero-information/1"
