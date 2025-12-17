#!/bin/bash

set -e

cd ../terraform

echo "=== Stage 1: Provisioning Infrastructure ==="

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


echo "Cosmos DB connection string: $COSMOS_DB_CONNECTION_STRING"
echo "Blob Storage connection string: $BLOB_STORAGE_ACCOUNT_CONNECTION_STRING"
echo "Event Grid topic endpoint: $EVENT_GRID_TOPIC_ENDPOINT"
echo "Event Grid Access key: $EVENT_GRID_TOPIC_KEY"
