# This script was created for testing image uploads
# to an Azure Blob Storage through the use of Azure CLI.
# It should be used as part of development and testing the solution during development.
# Container references the storage container name specified in storage.tf.
# Added --overwrite so no error on existing blob.
#
# Remember to login using 'az login'.
# Remember also to run the ./up.sh script first, in order to capture output variables from Terraform provisioning.

STORAGE_ACCOUNT=$(cd ../terraform && terraform output --raw storage_account_name)

az storage blob upload \
  --account-name "$STORAGE_ACCOUNT" \
  --container-name item-uploads \
  --name "Witch-Blade.png" \
  --file ../items/Witch-Blade.png \
  --overwrite true
