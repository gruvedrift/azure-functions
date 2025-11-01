#!/bin/bash

set -e

echo "=== Stage 1: Provisioning Infrastructure ==="
cd ./terraform

terraform init
terraform fmt
terraform validate
terraform apply -auto-approve

