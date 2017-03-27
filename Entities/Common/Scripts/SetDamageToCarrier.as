// SetDamageToCarrier.as

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	CPlayer@ player = attached.getPlayer();
	if(player !is null)
	{
		this.SetDamageOwnerPlayer(player);
	}
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	CPlayer@ player = inventoryBlob.getPlayer();
	if(player !is null)
	{
		this.SetDamageOwnerPlayer(player);
	}
}