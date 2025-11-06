## Essential CLI Commands for Azure Functions
```bash
# Create Function App 
az functionapp create \
  --name <name> \
  --storage-account <storage> \
  --consumption-plan-location <location> \
  --runtime python \
  --functions-version 4
  
# Deploy from zip 
az functionapp deployment source config-zip \
  --resource-group <rg> \
  --name <name> \
  --src <zip>
 
# Configure App settings 
az functionapp config appsettings set \
  --name <function-app-name> \
  --resource-group <rg> \
  --settings KEY=VALUE

# List functions
az functionapp function list \
  --name <function-app-name> \
  --resource-group <rg>

# Get function key
az functionapp function keys list \
  --name <function-app-name> \
  --resource-group <rg> \
  --function-name <function-name>

# Create a Custom Key 
az functionapp function keys set \
  --name <function-app-name>
  --resource-group <rg> \
  --function-name <function-name> \
  --key-name "new-custom-key" \
  --key-value "secret value" 

# Delete a key (Revoke access)
az functionapp function keys delete \
  --name <function-app-name> \
  --resource-group <rg> \
  --function-name <function-name> \
  --key-name "new-custom-key"

# Regenerate new default key (invalidates old key) 
az functionapp function keys set \
  --name <function-app-name> \
  --resource-group <rg> \
  --key-name default \
  --key-type functionKey
  
# Restart Function app
az functionapp restart \
  --name <function-app-name> \
  --resource-group <rg>
```