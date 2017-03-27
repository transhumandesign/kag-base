#include "DecayCommon.as";

//Adapted from ZeroZ30o's LanternAntiGrief v1
//Generalised by Geti

#define SERVER_ONLY

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 122; // opt
}

void onTick(CBlob@ this)
{
	CBlob@[] blobsInRadius;
	if (this.getMap().getBlobsInRadius(this.getPosition(), 64, @blobsInRadius))
	{
		string name = this.getName();

		int lanternCount = 0;
		Vec2f pos = this.getPosition();
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[(i * 997) % blobsInRadius.length];
			if (b !is this && b.getName() == name)
			{
				lanternCount++;
				if (lanternCount > 4)
				{
					SelfDamage(this);
					break;
				}
			}
		}
	}
}