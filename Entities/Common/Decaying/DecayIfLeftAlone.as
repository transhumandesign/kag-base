// damages stuff if they are left alone (no team member nearby and no base)

#include "DecayCommon.as";

#define SERVER_ONLY

const f32 SCREENSIZE = 550.0f;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 98; // opt
}

void onTick(CBlob@ this)
{
	if (dissalowDecaying(this))
		return;

	const u8 team = this.getTeamNum();
	CBlob@[] blobsInRadius;
	if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() + SCREENSIZE, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b.getTeamNum() == s32(team) && (b.hasTag("player") || b.hasTag("war_base")))
			{
				return;
			}
		}
	}

	if (DECAY_DEBUG)
		printf(this.getName() + " left alone ");
	SelfDamage(this);
}
