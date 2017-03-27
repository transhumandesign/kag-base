// damages stuff and times them out (if invincible) on land

#include "DecayCommon.as";

#define SERVER_ONLY

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_onground;
	this.getCurrentScript().tickFrequency = 41; // opt
}

void onTick(CBlob@ this)
{
	if (dissalowDecaying(this))
		return;

	if (!this.getMap().isInWater(this.getPosition() + Vec2f(0.0f, this.getHeight() / 2.0f)))
	{
		if (DECAY_DEBUG)
			printf(this.getName() + " decay on land");
		SelfDamage(this);
	}
}