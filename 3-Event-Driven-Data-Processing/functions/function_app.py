from PIL import Image
from datetime import datetime
import azure.functions as func
import io
import json
import logging
import uuid

app = func.FunctionApp()


@app.function_name(name="ProcessItemUpload")
@app.blob_trigger(
    arg_name="item_upload",
    path="item-uploads/{itemName}",
    connection="AzureWebJobsStorage"
)
@app.cosmos_db_output(
    arg_name="item_document",
    database_name="inventorydb",  # References the Cosmos DB name
    container_name="items",  # References the Cosmos DB sql container name
    connection="CosmosDbConnectionString"  # Reference in Application settings with connection string
)
def process_item_upload(
    item_upload: func.InputStream,
    item_document: func.Out[str],
):
    """
    - Triggers on image upload to Blob Storage
    - Validates image size
    - Creates an item document stub and uploads it to Cosmos DB ( Item container )
    """

    logging.info(f"Received upload: {item_upload}")
    logging.info(f"Processing upload: {item_upload.name}")
    # Read image data
    image_data = item_upload.read()

    if len(image_data) == 0:
        raise ValueError("Empty file upload!")

    img = Image.open(io.BytesIO(image_data))
    filesize_kb = len(image_data) / 1024
    width = img.size[0]
    height = img.size[1]
    # Size validation, default size is 88 x 64

    if width < 88 or height < 64:
        raise ValueError(f"Image too small: {width}x{height} (min 88x64)")

    # Extract item name from filename
    # Format "Glimmer-Cape.png" -> "Glimmer Cape"
    item_filename = item_upload.name.split('/')[-1]  # Remove url path.
    item_name_raw = item_filename.rsplit('.', 1)[0]  # Remove extension
    item_name = item_name_raw.replace('-', ' ')  # Remove dash

    # Create item listing with empty fields for Admin to fill out
    item_id = str(uuid.uuid4())

    item = {
        "id": item_id,
        "name": item_name,

        # Actual URL to item in database
        "imageUrl": f"item-uploads/{item_filename}",

        # Image metadata
        "metadata": {
            "imageHeight": height,
            "imageWidth": width,
            "imageFormat": img.format,
            "filesizeKB": round(filesize_kb, 2),
        },

        # Admin must fill out these
        "cost": None,
        "sellValue": None,
        "description": None,
        "itemType": None,

        # Stats admin must fill out
        "stats": {
            "intelligence": None,
            "strength": None,
            "agility": None,
            "attackDamage": None,
            "health": None,
            "healthRegeneration": None,
            "mana": None,
            "manaRegeneration": None,
        },

        # Metadata about status
        "status": "pending_admin_review",
        "createdAt": datetime.utcnow().isoformat(),
        "updatedAd": None,
        "reviewedBy": None,
    }

    # Upload document to Cosmos DB
    item_document.set(json.dumps(item))
    logging.info(f"Item stub created: {item_name} (ID: {item_id})")
    logging.info(f"Status: {item['status']}")
    logging.info(f"Image: {item['imageUrl']}")


@app.function_name(name="OnItemDocumentChange")
@app.cosmos_db_trigger(
    arg_name="documents",
    database_name="inventorydb",  # References Cosmos DB Database
    container_name="items",  # References Cosmos DB Container, which is essentially the same as a table
    connection="CosmosDbConnectionString",  # Connectivity type
    lease_container_name="leases",  # Progress tracking and fallback points for failing functions
)
@app.event_grid_output(
    arg_name="event_grid_event",
    topic_endpoint_uri="EventGridTopicEndpoint",  # Reference to Application settings variable
    topic_key_setting="EventGridTopicKey",  # Reference to Application setting variable

)
def on_item_document_change(
    documents: func.DocumentList,
    event_grid_event: func.Out[str]
):
    """
    Detects changes in Cosmos DB and publishes appropriate event onto Event Grid.
    Triggered automatically whenever a new document is created or an existing one is updated.

    Azure Functions will group multiple documents together if they change within a small time-window,
    especially if they are within the same partition. We should therefore iterate over
    multiple documents and support this feature.
    This is our PUBLISHER event, and the EventGrid event can hold whatever information we would like to.
    """
    logging.info("Function triggered from change in Cosmos DB")
    if documents:
        for doc in documents:
            item_document = json.loads(doc.to_json())
            logging.info(f"Change detected: {item_document['name']}, status: {item_document['status']}")

            if item_document['status'] == "pending_admin_review":
                event_type = "Inventory.ItemNeedsReview"

                # Minimal data for item review notification
                event_data = {
                    "itemId": item_document['id'],
                    "itemName": item_document['name'],
                    "itemStatus": item_document['status'],
                    "imageUrl": item_document['imageUrl'],
                    "createdAt": item_document.get('createdAt')
                }
            elif item_document['status'] == "approved":
                event_type = "Inventory.ItemApproved"

                # Full data for catalog and price history
                event_data = {
                    "itemId": item_document['id'],
                    "itemName": item_document['name'],
                    "itemStatus": item_document['status'],
                    "imageUrl": item_document['imageUrl'],
                    "createdAt": item_document.get('createdAt'),
                    "cost": item_document.get('cost'),
                    "sellValue": item_document.get('sellValue'),
                    "description": item_document.get('description'),
                    "itemType": item_document.get('itemType'),
                    "stats": item_document.get('stats', {}),
                    "reviewedBy": item_document.get('reviewedBy')
                }
            else:
                logging.info(f"Unknown document status, skipping...")
                continue

        # Create event for Event Grid
        # Cloud event type event, all the top level parameters are mandatory, except subject, time and data.
        event = {
            "specversion": "1.0",
            "id": str(uuid.uuid4()),
            "type": event_type,
            "source": "inventory-system/cosmos-db",
            "subject": f"items/{item_document['id']}",
            "time": datetime.utcnow().isoformat(),
            "data": event_data,
        }
        event_grid_event.set(json.dumps([event]))
        logging.info(f"Event published to Event Grid: {event_type}")


# Event Grid subscriber function
@app.function_name(name="SendAdminNotification")
@app.event_grid_trigger(arg_name="event")
def send_admin_notification(event: func.EventGridEvent):
    """
    Event Grid subscriber that receives ItemNeedsReview events.
    Logs what action an admin would need to take.

    In a real world implementation, this function could be responsible for notifications through email, Slack or BrevDue.
    """
    logging.info(f"=" * 80)
    logging.info("Event grid subscriber triggered!")
    logging.info(f"=" * 80)

    logging.info("")
    logging.info(f"Event Type: {event.event_type}")
    logging.info(f"Event Subject: {event.subject}")
    logging.info(f"Event ID: {event.id}")
    logging.info(f"Event Time: {event.event_time}")

    # Extract event data as specified in event producer function "OnItemDocumentChange"
    event_json = event.get_json()
    event_data = event_json.get('data', {})

    item_id = event_data.get('itemId', 'Unknown')
    item_name = event_data.get('itemName', 'Unknown')
    item_status = event_data.get('itemStatus', 'Unknown')
    image_url = event_data.get('imageUrl', 'Unknown')
    created_at = event_data.get('createdAt', 'Unknown')

    logging.info(f"")
    logging.info(f"-" * 80)
    logging.info(f"ITEM DETAILS:")
    logging.info(f"-" * 80)
    logging.info(f"Item Name:     {item_name}")
    logging.info(f"Item ID:       {item_id}")
    logging.info(f"Status:        {item_status}")
    logging.info(f"Image URL:     {image_url}")
    logging.info(f"Created At:    {created_at}")

    logging.info(f"")
    logging.info(f"-" * 80)
    logging.info(f"ADMIN ACTION REQUIRED")
    logging.info(f"-" * 80)
    logging.info(f"")
    logging.info(f"Item '{item_name}' needs review!")
    logging.info(f"")
    logging.info(f"Please update Cosmos DB document with:")
    logging.info(f"  • Cost (Gold)")
    logging.info(f"  • Sell Value (Cost / 2)")
    logging.info(f"  • Description (general information) ")
    logging.info(f"  • Item Type (Accessories, Support, Magical etc.)")
    logging.info(f"  • Stats: (Fill out the following, where applicable)")
    logging.info(f"      • Intelligence (Flat numerical or percentage gain / loss)")
    logging.info(f"      • Strength (Flat numerical or percentage gain / loss)")
    logging.info(f"      • Agility (Flat numerical or percentage gain / loss)")
    logging.info(f"      • Attack Damage (Flat numerical or percentage gain / loss)")
    logging.info(f"      • Health (Flat numerical or percentage gain / loss)")
    logging.info(f"      • Health Regeneration (Flat numerical or percentage gain / loss)")
    logging.info(f"      • Mana (Flat numerical or percentage gain / loss)")
    logging.info(f"      • Mana Regeneration (Flat numerical or percentage gain / loss)")
    logging.info(f"")
    logging.info(f"Cosmos DB Path:")
    logging.info(f"  Database:   inventorydb")
    logging.info(f"  Container:  items")
    logging.info(f"  Document:   {item_id}")
    logging.info(f"")
    logging.info(f"After updating, change status to 'approved' to publish item.")
    logging.info(f"Remember to add your username to the 'Reviewed by' section.")
    logging.info(f"")


# ApprovedItem Event Subscription function - Item Catalog
@app.function_name(name="UpdateStoreCatalog")
@app.event_grid_trigger(arg_name="approved_event")
@app.blob_input(
    arg_name="existing_catalog",
    path="store-catalog/item-catalog.json",
    connection="AzureWebJobsStorage"
)
@app.blob_output(
    arg_name="updated_catalog",
    path="store-catalog/item-catalog.json",  # All items written to single catalog file
    connection="AzureWebJobsStorage"
)
def update_store_catalog(
        approved_event: func.EventGridEvent,
        existing_catalog: func.InputStream,
        updated_catalog: func.Out[str]
):
    """
    Maintains a single JSON catalog file with list of all approved items.
    Appends new items to item list.

    Triggered by: Inventory.ItemApproved events
    Output: store-catalog/item-catalog.json
    """

    logging.info("Updating store catalog...")

    # Extract Event data
    event_json = approved_event.get_json()
    # Create catalog entry with admin provided item data
    catalog_item = {

        "id": event_json.get('itemId'),
        "name": event_json.get('itemName'),
        "imageUrl": event_json.get('imageUrl'),
        "cost": event_json.get('cost'),
        "sellValue": event_json.get('sellValue'),
        "description": event_json.get('description'),
        "itemType": event_json.get('itemType'),
        # Stats
        "stats": {
            "intelligence": event_json.get('stats', {}).get('intelligence'),
            "strength": event_json.get('stats', {}).get('strength'),
            "agility": event_json.get('stats', {}).get('agility'),
            "attackDamage": event_json.get('stats', {}).get('attackDamage'),
            "health": event_json.get('stats', {}).get('health'),
            "healthRegeneration": event_json.get('stats', {}).get('healthRegeneration'),
            "mana": event_json.get('stats', {}).get('mana'),
            "manaRegeneration": event_json.get('stats', {}).get('manaRegeneration')
        },
        # Metadata
        "reviewedBy": event_json.get('reviewedBy'),
        "approvedAt": datetime.utcnow().isoformat()
    }

    # Read existing catalog (or create new if doesn't exist)
    try:
        catalog_data = existing_catalog.read()
        if catalog_data:
            catalog_list = json.loads(catalog_data)
        else:
            catalog_list = []
            logging.info("Creating new catalog (no existing file)")
    except Exception as e:
        logging.warning(f"Could not read existing catalog, creating new: {e}")
        catalog_list = []

    catalog_list.append(catalog_item)

    # Write updated item catalog to Blob Container
    updated_catalog.set(json.dumps(catalog_list, indent=2))
    logging.info("")
    logging.info(f"Item written to catalog: {catalog_item['name']}")


# ApprovedItem Event Subscription function - Price History
@app.function_name(name="RecordPriceHistory")
@app.event_grid_trigger(arg_name="approved_event")
@app.table_output(
    arg_name="price_history",
    table_name="ItemPriceHistory",  # References Table Storage
    connection="AzureWebJobsStorage"
)
def record_price_history(
        approved_event: func.EventGridEvent,
        price_history: func.Out[str],
):
    """
    Records price history for analytics and trend detection.
    RowKey is mandatory in Azure Table Storage as it is combined with the PartitionKey to create a Primary Key.

    Triggered by: Inventory.ItemApproved events
    Output: ItemPriceHistory table
    """
    logging.info("Recording price history...")

    # Extract event data
    event_json = approved_event.get_json()
    item_id = event_json.get('itemId')
    timestamp = datetime.utcnow().isoformat()

    # Create Table Storage price entity
    price_entry = {
        "PartitionKey": item_id,
        "RowKey": str(uuid.uuid4()),
        "ItemId": item_id,
        "ItemName": event_json.get('itemName'),
        "Cost": event_json.get('cost'),
        "SellValue": event_json.get('sellValue'),
        "ReviewedBy": event_json.get('reviewedBy'),
        "RecordedAt": timestamp,
    }

    # Write to Table Storage
    price_history.set(json.dumps(price_entry, indent=2))
    logging.info(f"Price recorded: {price_entry['ItemName']} - {price_entry['Cost']} gold")
