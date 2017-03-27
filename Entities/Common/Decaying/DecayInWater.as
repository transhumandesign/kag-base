// damages stuff and times them out (if invincible) in water

#include "DecayCommon.as";

#define SERVER_ONLY

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_inwater;
	this.getCurrentScript().tickFrequency = 71; // opt
}

void onTick(CBlob@ this)
{
	if (dissalowDecaying(this) || this.isAttached())
		return;

	if (this.getMap().isInWater(this.getPosition() + Vec2f(0.0f, -this.getHeight() / 2.0f)))  // if submerged in water
	{
		if (DECAY_DEBUG)
			printf(this.getName() + " decay in water");
		SelfDamage(this);
	}
}