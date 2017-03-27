// Storage
		 
void onInit( CBlob@ this )
{
	this.getCurrentScript().tickFrequency = 61;
}

void onTick( CBlob@ this )
{
	PickUpIntoStorage( this );
}
 		   
void PickUpIntoStorage( CBlob@ this )
{
	CBlob@[] blobsInRadius;	   
	CMap@ map = this.getMap();
	if (map.getBlobsInRadius( this.getPosition(), this.getRadius()*1.5f, @blobsInRadius )) 
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			const string name = b.getName();
			if (b !is this && !b.isAttached() && b.isOnGround() && b.getShape().vellen < 0.1f
				&& (b.hasTag("material") || b.getName() == "scroll")
				&& !map.rayCastSolid(this.getPosition(), b.getPosition())
				)
			{
				this.server_PutInInventory(b);
			}
		}
	}
}