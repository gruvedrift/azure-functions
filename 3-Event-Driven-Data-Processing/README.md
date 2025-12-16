# Project Iteration 3: Event-Driven Data Processing 



### Service Bus vs Event Grid 
Complementary not replacements,  

**Service Bus purpose**: Reliable messaging for commands and items to work on.

**Service Bus Used for**: Background jobs (process this order), Work queues ("resize these 100 images"), Pont-to-point communication, when **guarantied processing** is needed.

architecture: 
```
Producer → Queue → Consumer
         ↑ Guaranteed delivery
         ↑ Ordered processing
         ↑ Retry logic
```


EG purpose: Broadcast **events** and **notifications**
EG-used for: "Something happened" notification, system-wide events ( blob created, VM started), Multiple reactions to same event, when you need **broadcasting**.

architecture: 
```
Publisher → Event Grid → Subscriber 1
                      → Subscriber 2
                      → Subscriber 3
         ↑ Pub/Sub pattern
         ↑ Multiple listeners
         ↑ Fast, lightweight
```

How they could work together: 
**Common pattern** 
- Event grid: "new order created" (broadcast notification)
- Service bus: "process order 123" ( work the item with retry ) // todo what is the item here

### Semi-BIS Terraform file structure: 
## File Structure Summary
```
terraform/
├── main.tf                       # Provider, resource group, random suffix
├── variables.tf                  # All input variables
├── storage.tf                    # Storage account, containers, tables
├── cosmosdb.tf                   # Cosmos DB, databases, containers
├── eventgrid.tf                  # Event Grid topic
├── eventgrid-subscriptions.tf    # Event Grid subscriptions (separate for clarity)
├── functions.tf                  # App Insights, Service Plan, Function App
└── outputs.tf                    # All outputs 
```

### storage.tf 
Used for image uploads and holding images

### cosmosdb.tf
Used for holding documents created by function and followup by administrator

### Overall project: 
1. upload item image
2. Blob trigger function ( automatically ) 
   1. Resize image (thumbnail + full image )
   2. Extract medata from filename
   3. Save to cosmos DB ( item listing)
   4. Save resized image back to blob
3. Cosmos DB change Feed Trigger (automatic)
   1. Publish to evnt grid "item-created" event
   2. Update search index 
   3. Send notification queue 
4. Event Grid trigger function (automatic)
   1. Send mail to admin: "item x needs stats!"

Everything will be automatic, the "user" just uploads an image and everything else happens

// TODO make this better, but it is overall the correct architecture
```mermaid
graph TD
    Upload[Uploads Image<br/>Messerschmidts-Reaver.png]
    Upload -->|Stored in| BlobStorage[(Blob Storage:</br><br/>item-uploads/)]
    BlobStorage -->|Triggers| BlobTrigger[Blob Trigger Function:</br><br/>ProcessItemUpload<br/><br/>1. Validate image<br/>2. Extract metadata<br/>3. Create stub in Cosmos]
    BlobTrigger -->|Create item description| CosmosDB[(Cosmos DB<br/>items container<br/><br/>status: pending)]
    CosmosDB -->|Change detected| CosmosTrigger[Cosmos DB Trigger:</br><br/>OnItemChanged<br/><br/>Checks status field:<br/>- pending --> ItemNeedsReview<br/>- approved --> ItemApproved]
    
    CosmosTrigger -->|Publish event| EventGrid[Event Grid Topic<br/>item-inventory-events]
    EventGrid -->|ItemNeedsReview|NotifyAdmin[Event Grid Trigger:<br/>SendAdminNotification]
    NotifyAdmin -->|Email|AdminEmail[Admin notified:</br><br/>New item needs review!]

    AdminEmail -->|Admin reviews|AdminAPI[Admin API Function:</br><br/>PATCH /admin/items/id<br/><br/>Updates:<br/>- price<br/>- stats<br/>- description<br/>- status: approved]
    AdminAPI -->|Update|CosmosDB

    %% Update Search Index
    EventGrid -->|ItemApproved|SearchIndex[Event Grid Trigger:<br/>UpdateSearchIndex]
    EventGrid -->|ItemApproved|Analytics[Event Grid Trigger:<br/>TrackItemAnalytics]

    SearchIndex -->|Write to|SearchTable[(Table Storage<br/>SearchIndex)]
    Analytics -->|Write to|AnalyticsTable[(Table Storage<br/>InventoryAnalytics)]
```


## Event Grid Subscriptions:
### Scope: 
Where to listen, this is configuring which event source the event grid subscription is subscribing to.
```hcl
scope = azurerm_eventgrid_topic.inventory_events.id
```
**Meaning:** "Listen to events published to MY custom topic"

**Resolves to:**

```
/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.EventGrid/topics/inventory-events-abc123
```
**How its used:**
```python
app.event_grid_output(
    arg_name="event",
    topic_endpoint="EventGridTopicEndpoint",  # Points to this topic
    topic_key="EventGridTopicKey"
)
def on_item_changed(documents, event):
    event.set(json.dumps([{
        "eventType": "Inventory.ItemNeedsReview",
        # ...
    }]))
    # Event goes to inventory-events topic
```
### Event types: 
Filters on which event that should trigger a subscription

```hcl
included_event_types = ["Inventory.ItemNeedsReview"]  #  Filter
```
In this project, we filter on two different events, but for three subscribers:
- ItemNeedsReview event &rarr; Only goes to SendAdminNotification 
- ItemApproved event &rarr; Goes to UpdateSearchIndex + InventoryAnalytics


#### Update search index: 
Purpose: Make approved items searchable. Cosmos DB is great for storing data, but not optimized for text search. This is why we want a **search-optimized index**

#### Track item analysis: 
Purpose: Collect metrics about inventory for dashboards and reports. 
- How many items created this week / month

## implementation plan: 

1) Blob trigger - Image processing
   1) Blob trigger (automatic file processing )
   2) Multiple output bindings  (blob + cosmos DB)
   3) Real image processing (resize)
   4) Metadata extraction
2) Cosmos DB change feed trigger - react to new patterns (on item created)
   1) Cosmos DB change feed (react to database change)
   2) Event grid output binding (publish event)
   3) Event-driven architecture
3) Event Grid Trigger - Send admin notification
   1) Event Grid trigger (react to system events)  
   2) Multiple subscribers to same event 
   3) Loose coupling 
4) Update search index on the same event. 
5) Analytics tracking also? All these three could happen on the same event


Other stuff to do: 
- Error handling and Retry policies : Blob trigger  (poison blob after max number of retries `host.json`)
- Cosmos DB trigger (retries from last checkpoint) // TODO find out what this means
- Event grid: dead letter destination for failures, built-in retry with exponential backoff. ( configure in event grid subscription )  


### Interesting test scenarios:
1. Upload invalid file (not an image) &rarr;Trigger should fail, retry, then poison queue
2. Cosmos DB unavailable (simulate by wrong connection string) &rarr; Blob trigger retries, eventually fails
3. Event Grid endpoint down &rarr; Event Grid retries with backoff, then dead letters
4.Duplicate processing (idempotency test) &rarr;  Upload same file twice  + Ensure no duplicate items in Cosmos DB


### Extra infrastructure needed 
- event grid topic 
- event subscription 
- storage containers ( item uploads, item thumbnail, items, leases - for change feed??)
- 


### Leases container: 
This is a container that is needed for the change feed trigger to track which items has been processed.
Its purpose is to track which changes has been processed and which function instance that is processing which partition.

It works as a checkpoint if a function crashes half-way through processing.


### What we will build 

* This is a commit test


### Common fail scenarios and outcome: 
``` 
Message has reached MaxDequeueCount of 5. Moving message to queue 'webjobs-blobtrigger-poison'.
```

### Running the function locally: 
1. Create the terraform outputs that we need for our bindings: 
   - Connection string to the Blob storage for image uploads 
   - Connection string to the storage account where the function will write documents
2. Capture them in a script, they are sensitive so we can not see them directly from the Terraform output.
3. Add them to your `local.settings.json` configuration so that your locally running function can interact with both databases.

Result:   
``` 
For detailed output, run func with --verbose flag.
[2025-12-16T09:18:03.059Z] Host lock lease acquired by instance ID '0000000000000000000000008BBD12A2'.
[2025-12-16T09:18:29.652Z] Executing 'Functions.ProcessItemUpload' (Reason='New blob detected(LogsAndContainerScan): item-uploads/Glimmer-Cape.png', Id=569b1ccd-0767-4f46-a14a-e4838b7e48fa)
[2025-12-16T09:18:29.653Z] Trigger Details: MessageId: 9e22a625-86fe-491c-a600-a68de3eb0cd4, DequeueCount: 1, InsertedOn: 2025-12-16T09:18:29.000+00:00, BlobCreated: 2025-12-16T09:18:24.000+00:00, BlobLastModified: 2025-12-16T09:18:24.000+00:00
[2025-12-16T09:18:29.688Z] Received upload: <azure.functions.blob.InputStream object at 0x1073d94f0>
[2025-12-16T09:18:29.688Z] Processing upload: item-uploads/Glimmer-Cape.png.png
[2025-12-16T09:18:29.739Z] Item stub created: Glimmer Cape (ID: 16028cb8-f8e1-407b-a6ef-405d4a1ae02b)
[2025-12-16T09:18:29.739Z] Status: pending_admin_review
[2025-12-16T09:18:29.740Z] Image: item-uploads/Glimmer-Cape.png.png
[2025-12-16T09:18:30.644Z] Executed 'Functions.ProcessItemUpload' (Succeeded, Id=569b1ccd-0767-4f46-a14a-e4838b7e48fa, Duration=1178ms)
```

You should now be able to observe the document created in the Cosmos DB Data explorer
![img](./img/cosmos-db-document.png)


### Test script 
I have added a script for testing uploads: `./test_upload.sh`. This script will use the Azure CLI and upload an image to the Azure Blob Storage, and thus trigger the 
azure function to create a new item document, and upload it to the Cosmos DB. 