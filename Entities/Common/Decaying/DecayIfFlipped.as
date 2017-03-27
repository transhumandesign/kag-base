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

	const f32 thresh = 45.0f;
	const f32 angle = this.getAngleDegrees();
	if (angle > thresh && angle < 360.0f - thresh)
	{
		if (DECAY_DEBUG)
			printf(this.getName() + " decay flipped");
		SelfDamage(this);
	}
}