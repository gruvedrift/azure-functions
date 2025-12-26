#!/bin/bash

set -e

cd ../terraform

echo ""
echo "=== Stage 1: Provisioning Core Infrastructure ==="

# Move eventgrid subscriptions out of Terraform scope temporarily
mkdir -p ./tmp_tf
mv eventgrid-subscriptions.tf ./tmp_tf

terraform init
terraform fmt
terraform validate
terraform apply -auto-approve

echo ""
echo "=== Stage 2: Package and Publish Azure Functions ==="

cd ../scripts
sh ./deploy_function.sh

echo ""
echo "=== Stage 3: Provisioning Eventgrid Subscriptions ==="

cd ../terraform
mv ./tmp_tf/eventgrid-subscriptions.tf ./

terraform init
terraform fmt
terraform validate
terraform apply -auto-approve


# Storage
COSMOS_DB_CONNECTION_STRING=$(terraform output --raw cosmos_db_connection_string)
BLOB_STORAGE_ACCOUNT_CONNECTION_STRING=$(terraform output --raw storage_connection_string)

# Event Grid
EVENT_GRID_TOPIC_ENDPOINT=$(terraform output --raw eventgrid_topic_endpoint)
EVENT_GRID_TOPIC_KEY=$(terraform output --raw eventgrid_topic_key)

echo ""
echo "Cosmos DB connection string: $COSMOS_DB_CONNECTION_STRING"
echo "Blob Storage connection string: $BLOB_STORAGE_ACCOUNT_CONNECTION_STRING"
echo "Event Grid topic endpoint: $EVENT_GRID_TOPIC_ENDPOINT"
echo "Event Grid Access key: $EVENT_GRID_TOPIC_KEY"
