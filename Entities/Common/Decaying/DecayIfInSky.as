#include "DecayCommon.as";

#define SERVER_ONLY

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 84; // opt
}

void onTick(CBlob@ this)
{
	if (dissalowDecaying(this))
		return;

	if (this.getPosition().y < this.getHeight())
	{
		if (DECAY_DEBUG)
			printf(this.getName() + " decay in sky");
		SelfDamage(this);
	}
}