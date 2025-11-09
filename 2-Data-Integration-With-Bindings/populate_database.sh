#!/bin/bash

set -e

cd ./terraform


# Needed for using the Azure Cosmos DB SQL API client library for Python!
pip install azure-cosmos

COSMOS_DB_CONNECTION_STRING=$(terraform output --raw cosmos_db_connection_string)
COSMOS_DATABASE_NAME=$(terraform output --raw cosmos_database_name)
COSMOS_CONTAINER_NAME=$(terraform output --raw cosmos_container_name)

export COSMOS_DB_CONNECTION_STRING
export COSMOS_DATABASE_NAME
export COSMOS_CONTAINER_NAME

python3 ../populate_database.py