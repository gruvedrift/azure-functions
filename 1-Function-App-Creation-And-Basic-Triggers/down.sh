#!/bin/bash

set -e

echo "Deleting Azure resources..."
cd ./terraform
terraform destroy -auto-approve