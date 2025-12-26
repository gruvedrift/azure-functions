#!/bin/bash

set -e
# This script was created for testing image uploads
# to an Azure Blob Storage through the use of Azure CLI.
# It should be used as part of development and testing the solution during development.
# Container references the storage container name specified in storage.tf.
# Added --overwrite so no error on existing blob.
#
# Remember to login using 'az login'.
# Remember also to run the ./up.sh script first, in order to capture output variables from Terraform provisioning.

STORAGE_ACCOUNT=$(cd ../terraform && terraform output --raw storage_account_name)
ITEMS=(
  Black-King-Bar
  Blink-Dagger
  Glimmer-Cape
  Scythe-Of-Vyse
  Witch-Blade

)

for item in "${ITEMS[@]}"; do
  echo ""
  echo "Uploading item: ${item}..."
  az storage blob upload \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name item-uploads \
    --name "${item}.png" \
    --file ../items/"${item}".png \
    --overwrite true
done

