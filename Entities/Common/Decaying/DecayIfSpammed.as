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

		int blobCount = 0;
		float lowestHealth = this.getInitialHealth();
		CBlob@ lowestBlob;

		Vec2f pos = this.getPosition();
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob@ b = blobsInRadius[i];
			if (b.getName() != name || 
			    b.isAttached() ||
			    b.isInInventory())
				continue;

			blobCount++;

			float blobHealth = b.getHealth();
			if (blobHealth < lowestHealth)
			{
				@lowestBlob = @b;
				lowestHealth = blobHealth;
			}


		}

		if (blobCount > 4)
		{
			// if no lowest blob is found, damage self
			// so other blobs will select this blob as lowest
			if (lowestBlob is null || lowestBlob is this)
			{
				SelfDamage(this);
			}
		}

	}
}