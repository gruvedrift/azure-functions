import sys
from datetime import datetime
from azure.cosmos import CosmosClient
import os

database_client = CosmosClient(
    url=os.getenv("COSMOS_ENDPOINT"),
    credential=os.getenv("COSMOS_KEY")
)

container = database_client.get_database_client(database="inventorydb").get_container_client("items")

if len(sys.argv) == 1:
    # List Document ID's
    item_documents = container.query_items(
        query="SELECT c.id, c.name, c.status FROM c",
        enable_cross_partition_query=True
    )
    print("")
    for item in item_documents:
        print(f"{item['id']}\t{item['name']}\t{item['status']}")
else:
    # Patch item with stats and approve
    item = container.read_item(item=sys.argv[1], partition_key=sys.argv[1])
    # Witch Blade item
    item.update({
        'status': 'approved',
        'cost': 2775,
        'sellValue': 1387,
        'description': 'A spiteful blade inadvertently possessed by the soul of its incautious creator.',
        'itemType': 'Magical',
        'reviewedBy': 'OSFrog',
        'updatedAt': datetime.utcnow().isoformat()
    })
    item['stats'].update({
        'intelligence': 12,
        'strength': 0,
        'agility': 0,
        'attackDamage': 0,
        'health': 0,
        'healthRegeneration': 0,
        'mana': 0,
        'manaRegeneration': 1.5,
    })
    container.upsert_item(item)
    print("")
    print(f"Updated item: {item['name']}!")