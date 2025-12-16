#!/bin/bash

set -e

cd ../terraform

echo "=== Stage 1: Provisioning Infrastructure ==="

terraform init
terraform fmt
terraform validate
terraform apply -auto-approve

COSMOS_DB_CONNECTION_STRING=$(terraform output --raw cosmos_db_connection_string)
BLOB_STORAGE_ACCOUNT_CONNECTION_STRING=$(terraform output --raw storage_connection_string)
echo "Cosmos DB connection string: $COSMOS_DB_CONNECTION_STRING"
echo "Blob Storage Account connection string: $BLOB_STORAGE_ACCOUNT_CONNECTION_STRING"
