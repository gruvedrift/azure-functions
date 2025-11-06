#!/bin/bash

set -e

echo "=== Stage 1: Provisioning Infrastructure ==="
cd ./terraform

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
echo "Deployment complete!"
echo "Test HttpTrigger with: curl $FUNCTION_APP_URL/api/greet?name=Jesse"
echo "Observe TimerTrigger firing within Function App metrics or logs. "