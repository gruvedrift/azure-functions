# Project Iteration 2: Data Integration With Bindings 

### Syllabus objectives covered: 

- Implement input and output bindings

### Learning goals:

Master Azure Functions bindings to seamlessly integrate with Azure services without writing complex integration code.

### Project Description:
Enhance your notification system to read data from various Azure services and write results to different destinations. 
Implement input bindings that automatically provide data to your functions and output bindings that store results.

### Implementation steps:

1. Add Cosmos DB input binding to read hero information
2. Implement Blob Storage output binding to archive notifications
3. Create Service Bus output binding for reliable message delivery
4. Add Table Storage binding for tracking notification history
5. Configure binding connection strings and authentication
6. Test data flow through multiple bindings in a single function

## Note on Bindings:

Bindings are Azures declarative way to connect functions to Azure resources. In Python v2, bindings are implemented as decorators, as we will soon see.
They let us specify WHAT we want, instead of HOW we want it. Bindings eliminate boilerplate code for connections, authentication, serialization and error handling. 

#### Key characteristics
- **Declarative** - Specify WHAT we want, not HOW
- **Two types** - Input bindings (read data) and Output bindings (write data) 
- **Automatic plumbing** - Azure handles connections, authentication, retries etc...
- **Reduces boilerplate** - Eliminates many lines of SDK/connection code per integration
- **Built-in support** - Ready-to-use integration for Cosmos DB, Storage, Service Bus, Event Grid etc...

```python
# Example 
@app.cosmos_db_input(database_name="user-db", container_name="Users", ...)
def my_function(req, user):  # 'user' automatically loaded from Cosmos DB
    # No connection code needed!
    return func.HttpResponse(f"Hello {user['name']}")
```

### Quick note on partition keys:
This demonstration is not centered around CosmosDB, but it is worth mentioning that a **Partition Key** is a field CosmosDB uses to distribute
data across physical partitions for scale.
```json
{
  "userId": "user123",  <- this is the partition key
  "name": "Jesse",
  "email": "jesse@example.com"
}
```
All documents with the same `userId` are stored together (co-located).

### Table comparison cosmos DB vs relation database:
| Concept           | Description                                      | Analogy                       |
|-------------------|--------------------------------------------------|-------------------------------|
| **Account**       | The overall Cosmos DB resource in Azure          | Like a database server        |
| **Database**      | A logical grouping of containers                 | Like a database in SQL Server |
| **Container**     | Where JSON documents live (scales independently) | Like a table, but schema-less |
| **Item**          | A single JSON document                           | Like a row, but flexible      |
| **Partition key** | Used to group & scale items                      | Like a sharding key           |


## 1. Add Cosmos DB input binding to read hero information:

### Implementation: Cosmos DB Input Binding: 

For implementation details take a look at the sample code in `/functions/function_app.py` file.
```python
# Bindings explanation
@app.cosmos_db_input(
    arg_name="hero_information",             # Parameter name in function signature ( can be named anything )
    database_name="herodb",                  # Cosmos DB database name
    container_name="hero-information",       # Container where documents live
    connection="CosmosDbConnectionString",   # App setting name with connection string
    id="{heroId}",                           # Document ID from route parameter
    partition_key="{heroId}",                # Partition key value (same as ID in this case)
)
```
**Key concepts:**
- **Binding expressions** - `{heroId}` pulls from route parameter automatically
- **arg_name** - The `hero_information` parameter is injected by Azure, so no manual loading needed
- **connection** - References the app setting configured in Terraform: `"CosmosDBConnectionString" `

### How to set up and test Input Bindings: 
1. run `./up.sh` (Provisions infrastructure and terraform outputs)
2. run `./populate_database.sh` 
   - Installs the `Azure Cosmos` client library for Python
   - Retrieves Cosmos DB connection details from Terraform output 
   - Invokes the Python script: `./populate_database.py` which: 
   - Connects to the Cosmos DB and populates it with testdata. 
3. Verify data in portal: Azure Portal &rarr; Cosmos DB &rarr; Data Explorer &rarr; herodb &rarr; hero-information &rarr; Items
4. Run curls against the azure function!
```bash
curl https://linux-function-app-2hqhnb.azurewebsites.net/api/hero-information/1

# Should return: 
{
    "id": "1",
    "heroId": "1",
    "name": "Invoker",
    "attackType": "Ranged",
    "primaryAttribute": "Intelligence",
    "roles": [
        "Mid",
        "Nuker",
        "Disabler"
    ],
    "difficulty": "Hard",
    "_rid": "+agwAMqK-KkBAAAAAAAAAA==",
    "_self": "dbs/+agwAA==/colls/+agwAMqK-Kk=/docs/+agwAMqK-KkBAAAAAAAAAA==/",
    "_etag": "\"0000bf00-0000-0c00-0000-690fae880000\"",
    "_attachments": "attachments/",
    "_ts": 1762635400
}
```
You should also se the function log the request: 
![image](./img/function-binding-log.png)


## 2. Implement Blob Storage output binding to archive notifications

Output bindings save data when a function completes, it basically saves the result automatically.  
For this demonstration we will add an output biding to our existing `hero-information` function, however, we will create a new function just to keep them separated.
Similarly to the Input Binding, it is very easy to configure the decorator: 
```python
@app.blob_output(
    arg_name="archive",                                       # Parameter name in function
    path="hero-archive-audit/hero-{heroId}-{datetime}.json",  # Dynamic blob path
    connection="AzureWebJobsStorage"                          # Storage connection string
)
   
# Now, the 
def get_hero_information_with_audit(
        req: func.HttpRequest,
        document_list: func.DocumentList,
        archive: func.Out[str]                                # Output binding parameter from Decorator
) -> func.HttpResponse:
```
⚠️ **Important:** The Blob path prefix must match your container name:

**Container name in Terraform:**
```hcl
name = "hero-archive-audit"
```

**Path prefix in binding:**
```python
path = "hero-archive-audit/hero-{heroId}-{datetime}.json"
                &uarr; Must match container name ❗
```

If they don't match, you'll get a 404 error when trying to save blobs.

### How to test: 
After running the `./up.sh` script, do some curl requests against the new function endpoint!  
We will get the same response as for the function with only Input Binding, but every audit is also archived to the Storage Blob we provisioned. 

**Verify Archive in Azure Portal:**
1. Navigate to Storage Account → **Containers**
2. Open **hero-archive-audit** container
3. See your archived JSON files with timestamps

![img](./img/hero-archive-audit-items.png)



## Key Learning Questions:

#### How do bindings differ from manually using Azure SDKs in your function code? 

TODO: Answer

#### What happens when an output binding fails while your function logic succeeds? 

TODO: Answer

#### How can you use multiple output bindings to write to different services atomically? 
