// SetDamageToCarrier.as

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	CPlayer@ player = attached.getPlayer();
	if (player !is null)
	{
		if (this.getName() == "keg")
		{
			s32 timer = this.get_s32("explosion_timer") - getGameTime();
			if (timer > 60 || timer < 0 || this.getDamageOwnerPlayer() is null)
			{
				this.SetDamageOwnerPlayer(player);
			}
		}
		else 
		{
			this.SetDamageOwnerPlayer(player);
		}
	}
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (inventoryBlob.getName() == "crate")
	{
		return;
	}
	CPlayer@ player = inventoryBlob.getPlayer();
	if (player !is null)
	{
		this.SetDamageOwnerPlayer(player);
	}
}
