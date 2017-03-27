// SetTeamToCarrier.as

#define SERVER_ONLY

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	this.server_setTeamNum(attached.getTeamNum());
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.server_setTeamNum(inventoryBlob.getTeamNum());
}