#include "DecayCommon.as";

#define SERVER_ONLY

u8 team0count = 0;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 800;
	team0count = getRules().get_u8("team 0 count"); // global
}

void onTick(CBlob@ this)
{
	if (dissalowDecaying(this) || this.isAttached() || this.getTickSinceCreated() < 1000)
		return;

	int quantity = this.getQuantity();
	if (quantity > 100)
		quantity -= 10;
	else if (quantity > 0)
		quantity -= 20;

	if (quantity <= 0)
	{
		this.server_Die();
		return;

	}

	this.server_SetQuantity(quantity);

	if (team0count > 9) // faster decay with many players
	{
		this.getCurrentScript().tickFrequency = 400;
	}
}