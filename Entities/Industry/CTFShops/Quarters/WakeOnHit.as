// WakeOnHit.as

#include "KnockedCommon.as"

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	if (this.getHealth() < oldHealth)
	{
		CBlob@ bed = this.getAttachments().getAttachmentPointByName("BED").getOccupied();
		if (bed !is null)
		{
			this.getSprite().PlaySound("WilhelmShort.ogg");
			if (getNet().isServer())
			{
				this.server_DetachFrom(bed);
			}
			if (isKnockable(this))
			{
				setKnocked(this, 30);
			}
		}
	}
}
