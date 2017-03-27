#define SERVER_ONLY

#include "../Attacks/Hitters.as"

void onInit(CBlob@ this)
{
	// crushing
	this.getCurrentScript().tickFrequency = 9;
	this.getCurrentScript().runFlags |= Script::tick_not_sleeping;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

// check for crushing

void onTick(CBlob@ this)
{
	if ((this.wasOnGround() || !this.isOnGround()))
	{
		CBlob@[] overlapping;

		if (this.getOverlapping(@overlapping))
		{
			for (uint i = 0; i < overlapping.length; i++)
			{
				CBlob@ blob = overlapping[i];

				if (blob.getPosition().y - blob.getRadius() < this.getPosition().y || blob.getMass() > this.getMass())
				{
					continue;
				}

				// hack: for removing boat hitting blobs while net is desynced
				//if (this.getShape().getConsts().transports && blob.getPosition().y - blob.getRadius() < this.getPosition().y) {
				//  return;
				//}

				f32 crush = blob.getShape().getVars().totalImpulse;
				f32 thresh =  0.00005f * blob.getMass();

				if (crush > thresh)
				{
					//  printFloat("crush force", crush);
					this.server_Hit(blob, this.getPosition(), this.getVelocity(), crush * 100.0f, Hitters::crush, true);
				}
			}
		}
	}
}
