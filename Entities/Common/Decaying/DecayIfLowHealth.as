// damages stuff if it is really low on health

#include "DecayCommon.as";

#define SERVER_ONLY

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 121; // opt
}

void onTick(CBlob@ this)
{
	if (dissalowDecaying(this) || this.isAttached())
		return;

	if (this.getHealth() < this.getInitialHealth() * 0.1f)
	{
		if (DECAY_DEBUG)
			printf(this.getName() + " decay low on health");
		SelfDamage(this, 0.33f);
	}
}