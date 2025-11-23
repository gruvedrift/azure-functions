import datetime
import json
import logging
import sys
import uuid

from PIL import Image
import io


def process_item_upload(
        item_file_name
):
    """
    - Reacts to image upload on Blob
    - Validates image size
    - Creates an item document stub to be loaded into Cosmos DB
    """

    logging.info(f"Processing upload: {item_file_name}.png")
    print(f"Processing upload: {item_file_name}.png")
    with open(f"../items/{item_file_name}.png", "rb") as item:
        image_data = item.read()

    img = Image.open(io.BytesIO(image_data))

    # Size validation, default size is 88 x 64
    if img.size[0] < 88 or img.size[1] < 64:
        raise ValueError("Image too small!")

    item_name = item_file_name.replace('-', ' ')
    print(f"item name {item_name}")

    # Create item listing with empty fields for Admin to fill out
    item_id = str(uuid.uuid4())
    print(item_id)

    item = {
        "id": item_id,
        "name": item_name,

        # Actual URL to item in database?
        "imageUrl": f"item-uploads/{item_file_name}.png",
        "imageHeight": img.size[0],
        "imageWidth": img.size[1],
        "imageFormat": img.format,

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

    print(json.dumps(item))



if __name__ == "__main__":
    filename = sys.argv[1]
    process_item_upload(filename)
