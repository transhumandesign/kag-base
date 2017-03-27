// WakeOnHit.as

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	if (this.getHealth() < oldHealth)
	{
		CBlob@ bed = this.getAttachments().getAttachedBlob("BED");
		if (bed !is null)
		{
			this.getSprite().PlaySound("WilhelmShort.ogg");
			if (getNet().isServer())
			{
				this.server_DetachFrom(bed);
			}
			if (this.exists("knocked"))
			{
				this.set_u8("knocked", 30);
			}
		}
	}
}