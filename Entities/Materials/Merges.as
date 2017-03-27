// Blob merging   // requires set_u16("max");

#define SERVER_ONLY

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_onground;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().tickFrequency = 49;
}

void onTick(CBlob@ this)
{
	if (this.isInInventory())
	{
		return;
	}
	if (this.getQuantity() < this.maxQuantity)
	{
		CBlob@[] blobsInRadius;
		if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() * 6.0f, @blobsInRadius))
		{
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob @blob = blobsInRadius[i];

				if (AttemptMergeWith(this, blob)) return; //one at a time
			}
		}
	}
}

// character was placed in crate

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (inventoryBlob is null) return;

	CInventory@ inv = inventoryBlob.getInventory();

	if (inv is null) return;

	for (int i = 0; i < inv.getItemsCount(); i++)
	{
		CBlob@ blob = inv.getItem(i);
		if (AttemptMergeWith(this, blob)) return; //one at a time
	}
}

bool AttemptMergeWith(CBlob@ this, CBlob@ blob)
{
	if (blob !is this && blob.isOnGround() &&
	        !blob.isAttached() && !blob.isInInventory() &&
	        blob.getQuantity() < blob.maxQuantity &&
	        blob.getName() == this.getName() &&
	        !blob.hasTag("merged")
	   ) // same name = merge
	{
		if (this.getQuantity() < blob.getQuantity())
		{
			blob.server_SetQuantity(blob.getQuantity() + this.getQuantity());
			this.Tag("merged");
			this.server_Die();
		}
		else
		{
			this.server_SetQuantity(blob.getQuantity() + this.getQuantity());
			blob.Tag("merged");
			blob.server_Die();
		}

		return true; // one at a time
	}
	return false;
}
