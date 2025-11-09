#!/bin/bash

set -e

echo "Deleting Azure resources..."
cd ./terraform
terraform destroy -auto-approve

echo ""
echo "Tear-down completed!"
