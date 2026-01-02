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
## Essential  CLI commands for Event Grid
```bash
# Create Event Grid topic
az eventgrid topic create \
  --name <topic-name> \
  --resource-group <rg> \
  --location <location> \
  --input-schema CloudEventSchemaV1_0

# Get topic endpoint
az eventgrid topic show \
  --name <topic-name> \
  --resource-group <rg> \
  --query "endpoint" \
  --output tsv

# Get topic access key
az eventgrid topic key list \
  --name <topic-name> \
  --resource-group <rg> \
  --query "key1" \
  --output tsv

# Create event subscription
az eventgrid event-subscription create \
  --name <subscription-name> \
  --source-resource-id /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.EventGrid/topics/<topic-name> \
  --endpoint <webhook-url> \
  --included-event-types <event-type> \
  --event-delivery-schema CloudEventSchemaV1_0

# List event subscriptions
az eventgrid event-subscription list \
  --source-resource-id /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.EventGrid/topics/<topic-name> \
  --output table

# Delete event subscription
az eventgrid event-subscription delete \
  --name <subscription-name> \
  --source-resource-id /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.EventGrid/topics/<topic-name>
```