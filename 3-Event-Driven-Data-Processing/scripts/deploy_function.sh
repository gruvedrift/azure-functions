#!/bin/bash

# Grab Terraform outputs for deployment
cd ../terraform

FUNCTION_APP_NAME=$(terraform output --raw function_app_name)
echo ""
echo "=== Stage 2.1 Creating Deployment package for Azure Functions ==="

cd ../functions
zip deploy.zip function_app.py host.json requirements.txt

echo ""
echo "=== Stage 2.2: Deploying Azure Functions package to Azure ==="
echo ""
# Pillow libray is NOT available in runtime by default, so use func publish, which includes the necessary Python packages in the deployment bundle.
func azure functionapp publish "$FUNCTION_APP_NAME" --python
