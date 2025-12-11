
#define SERVER_ONLY;

// Use `.set_u8("decay time", ..)` to define how long it takes for the blob to disappear when unused
// Use `.Tag("decay not moving") to keep blob from disappearing while moving 

void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(this.get_u16("decay time"));
	this.getCurrentScript().tickIfTag = "decay not moving";
	this.getCurrentScript().tickFrequency = 60;
}

void onTick(CBlob@ this)
{
	if (this.isAttached() || this.hasAttached())
	{
		return;
	}

	if (this.getVelocity().LengthSquared() > 1.0f)
	{
		this.server_SetTimeToDie(this.get_u16("decay time")); // moving, reset timer
	}
}

void onDetach(CBlob@ this, CBlob@ blob, AttachmentPoint@ point)
{
	this.server_SetTimeToDie(this.get_u16("decay time"));
}

void onThisRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	this.server_SetTimeToDie(this.get_u16("decay time"));
}

void onAttach(CBlob@ this, CBlob@ blob, AttachmentPoint@ point)
{
	this.server_SetTimeToDie(-1);
}

void onThisAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.server_SetTimeToDie(-1);
}
