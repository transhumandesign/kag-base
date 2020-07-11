#define SERVER_ONLY

#include "CratePickupCommon.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 12;
	this.getCurrentScript().removeIfTag = "dead";
}

void Take(CBlob@ this, CBlob@ blob)
{
	const string blobName = blob.getName();

	if (
		blobName == "mat_gold" && pickupCriteria(this, blob, 50) ||
		blobName == "mat_stone" ||
		blobName == "mat_wood"
	) {
		if ((blob.getDamageOwnerPlayer() !is this.getPlayer()) || getGameTime() > blob.get_u32("autopick time"))
		{
			if (this.server_PutInInventory(blob))
			{
				return;
			}
		}
	}

	CBlob@ carryblob = this.getCarriedBlob();
	if (carryblob !is null && carryblob.getName() == "crate")
	{
		if (crateTake(carryblob, blob))
		{
			return;
		}
	}
}

bool pickupCriteria(CBlob@ this, CBlob@ blob, uint16 quantity)
{
	return blob.getQuantity() >= quantity || this.hasBlob(blob.getName(), 1);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || blob.getShape().vellen > 1.0f)
	{
		return;
	}

	Take(this, blob);
}

void onTick(CBlob@ this)
{
	CBlob@[] overlapping;

	if (this.getOverlapping(@overlapping))
	{
		for (uint i = 0; i < overlapping.length; i++)
		{
			CBlob@ blob = overlapping[i];
			{
				if (blob.getShape().vellen > 1.0f)
				{
					continue;
				}

				Take(this, blob);
			}
		}
	}
}

// make ignore collision time a lot longer for auto-pickup stuff
void IgnoreCollisionLonger(CBlob@ this, CBlob@ blob)
{
	if (this.hasTag("dead"))
	{
		return;
	}

	const string blobName = blob.getName();

	if (blobName == "mat_gold" || blobName == "mat_stone" ||
	        blobName == "mat_wood" || blobName == "grain")
	{
		blob.set_u32("autopick time", getGameTime() +  getTicksASecond() * 7);
		blob.SetDamageOwnerPlayer(this.getPlayer());
	}
}


void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	IgnoreCollisionLonger(this, detached);
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	IgnoreCollisionLonger(this, blob);
}
