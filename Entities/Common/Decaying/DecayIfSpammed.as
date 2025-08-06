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
	if (disallowDecaying(this))
		return;

	CBlob@[] blobsInRadius;
	if (this.getMap().getBlobsInRadius(this.getPosition(), 64, @blobsInRadius))
	{
		string name = this.getName();

		int sameBlobCount = 0;
		u16[] blobNetIDsToDamage;

		// first loop - finding and counting same blobs
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob@ b = blobsInRadius[i];
			if (b is null || b.getName() != name)
				continue;

			blobNetIDsToDamage.insertLast(b.getNetworkID());
			sameBlobCount++;
		}

		blobNetIDsToDamage.sortAsc();

		// second loop - damaging blobs
		u16 numberOfBlobsToDamage = blobNetIDsToDamage.length;
		u8 spamLimit = this.exists("spam limit") ? this.get_u8("spam limit") : 5;
		if (numberOfBlobsToDamage < spamLimit)
			return;

		for (uint j = spamLimit; j < numberOfBlobsToDamage; j++)
		{
			CBlob@ b = getBlobByNetworkID(blobNetIDsToDamage[j]);
			if (b !is null && b is this) // 'this' solely responsible for hurting itself
			{
				SelfDamage(b);
			}
		}
	}
}
