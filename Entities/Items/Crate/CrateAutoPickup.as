#define SERVER_ONLY

#include "CratePickupCommon.as"

void onInit(CBlob@ this)
{
    this.getCurrentScript().tickFrequency = 60;
    this.getCurrentScript().removeIfTag = "dead";
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
    if (blob is null || blob.getShape().vellen > 1.0f)
    {
        return;
    }

    crateTake(this, blob);
}

void onTick(CBlob@ this)
{
    CBlob@[] overlapping;

    if (this.getOverlapping(@overlapping))
    {
        for (uint i = 0; i < overlapping.length; i++)
        {
            CBlob@ blob = overlapping[i];

			if (blob is null 
				|| blob.isAttached() 
				|| !blob.canBePickedUp(this)
				|| blob.getShape().vellen > 1.0f
				)
			{
				continue;
			}

			crateTake(this, blob);
        }
    }
}


