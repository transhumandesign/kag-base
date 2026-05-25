// WakeOnHit.as

#include "KnockedCommon.as"
#include "Hitters.as"

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
				setKnocked(this, 30, true);
			}
		}
	}
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	if (customData == Hitters::water_stun_force)
	{
		CBlob@ bed = this.getAttachments().getAttachmentPointByName("BED").getOccupied();
		if (bed !is null)
		{
			if (isServer())
			{
				this.server_DetachFrom(bed);
			}
		}
	}
	
	return damage;
}
