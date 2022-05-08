// SetTeamToCarrier.as

#define SERVER_ONLY

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	if (this.getName() == "crate" && !this.exists("packed"))
	{
		return;
	}
	
	CBlob@ carried = attached.getCarriedBlob();
	
	if (carried !is null)
	{
		if (carried.getName() == this.getName())
		{
			this.server_setTeamNum(attached.getTeamNum());
		}
	}
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (inventoryBlob.getName() == "crate")
	{
		return;
	}
	this.server_setTeamNum(inventoryBlob.getTeamNum());
}
