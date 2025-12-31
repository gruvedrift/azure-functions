#!/bin/bash

set -e

# Install Cosmos DB extension in order to do item listings
cd ../terraform

export COSMOS_ENDPOINT=$(terraform output -raw cosmos_endpoint)
export COSMOS_KEY=$(az cosmosdb keys list \
  -g $(terraform output -raw resource_group_name) \
  -n $(terraform output -raw cosmos_account_name) \
  --query primaryMasterKey -o tsv)

cd ../scripts
pip3 install -r requirements.txt

if [ -n "$1" ]; then
  echo ""
  python3 ./test.py "$1"
else
  echo ""
  python3 ./test.py
fi