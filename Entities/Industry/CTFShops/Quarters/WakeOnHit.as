// WakeOnHit.as

#include "KnockedCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("wake client");
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	if (this.getHealth() < oldHealth)
	{
		CBlob@ bed = this.getAttachments().getAttachmentPointByName("BED").getOccupied();
		if (bed !is null)
		{
			this.SendCommand(this.getCommandID("wake client"));
		
			if (isServer())
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

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("wake client") && isClient())
	{
		this.getSprite().PlaySound("WilhelmShort.ogg");
	}
}
