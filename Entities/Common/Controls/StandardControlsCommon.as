
void server_Pickup(CBlob@ this, CBlob@ picker, CBlob@ pickBlob)
{
	if (pickBlob is null || picker is null || pickBlob.isAttached())
		return;
	CBitStream params;
	params.write_netid(picker.getNetworkID());
	params.write_netid(pickBlob.getNetworkID());
	this.SendCommand(this.getCommandID("pickup"), params);
}

void server_PutIn(CBlob@ this, CBlob@ picker, CBlob@ pickBlob)
{
	if (pickBlob is null || picker is null)
		return;
	CBitStream params;
	params.write_netid(picker.getNetworkID());
	params.write_netid(pickBlob.getNetworkID());
	this.SendCommand(this.getCommandID("putin"), params);
}

void Tap(CBlob@ this)
{
	this.set_s32("tap_time", getGameTime());
}

void TapPickup(CBlob@ this)
{
	this.set_s32("tap_pickup_time", getGameTime());
}

bool isTap(CBlob@ this, int ticks = 15)
{
	return (getGameTime() - this.get_s32("tap_time") < ticks);
}

bool isTapPickup(CBlob@ this, int ticks = 15)
{
	// TODO: merge some code with the above and make it generalized to all keys if ever useful
	return (getGameTime() - this.get_s32("tap_pickup_time") < ticks);
}