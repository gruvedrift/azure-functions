from PIL import Image
import azure.functions as func
import io
import datetime
import json
import logging
import uuid

app = func.FunctionApp()


@app.function_name(name="ProcessItemUpload")
@app.blob_trigger(
    arg_name="item_upload",
    path="item-uploads/{itemName}",
    connection="AzureWebJobsStorage"       # References the Application settings with storage connection string ( Variable -> Variable -> connection string )
)
@app.cosmos_db_output(
    arg_name="item_document",
    database_name="inventorydb",           # References the Cosmos DB name
    container_name="items",                # References the Cosmos DB sql container name
    connection="CosmosDbConnectionString"  # Reference in Application settings with connection string
)
def process_item_upload(
        item_upload: func.InputStream,
        item_document: func.Out['str'],
):
    """
    - Triggers on image upload to Blob Storage
    - Validates image size
    - Creates an item document stub and uploads it to Cosmos DB ( Item container )
    """

    logging.info(f"Received upload: {item_upload}")
    logging.info(f"Processing upload: {item_upload.name}.png")
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

        # Actual URL to item in database?
        "imageUrl": f"item-uploads/{item_filename}.png",

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
        "createdAt": datetime.datetime.utcnow().isoformat(),
        "updatedAd": None,
        "reviewedBy": None,
    }

    # Upload document to Cosmos DB
    item_document.set(json.dumps(item))

    logging.info(f"Item stub created: {item_name} (ID: {item_id})")
    logging.info(f"Status: {item['status']}")
    logging.info(f"Image: {item['imageUrl']}")
