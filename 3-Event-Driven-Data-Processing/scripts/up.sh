#!/bin/bash

set -e

cd ../terraform

echo "=== Stage 1: Provisioning Infrastructure ==="

terraform init
terraform fmt
terraform validate
terraform apply -auto-approve