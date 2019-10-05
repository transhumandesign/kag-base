// set ladder if we're on it, otherwise set false

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_not_onground;
}

void onTick(CBlob@ this)
{
	// const bool pressingKey = this.isKeyPressed(key_up) || this.isKeyPressed(key_down);
	// const bool climbLadder = this.isOnLadder() || (!this.wasOnLadder() && pressingKey);

	ShapeVars@ vars = this.getShape().getVars();
	vars.onladder = false;

	//check overlapping objects

	CBlob@[] overlapping;
	if (this.getOverlapping(@overlapping))
	{
		for (uint i = 0; i < overlapping.length; i++)
		{
			CBlob@ overlap = overlapping[i];
			//printf("overlap "  + overlap.getName() );

			if (overlap.isLadder() && !overlap.isAttachedTo(this))
			{
				vars.onladder = true;
				return;
				//CBlob@[] blobsInRadius;
				//CMap@ map = this.getMap();
				//if (map.getBlobsInRadius( this.getPosition(), this.getRadius(), @blobsInRadius ))
				//{
				//	for (uint i = 0; i < blobsInRadius.length; i++)
				//	{
				//		CBlob @b = blobsInRadius[i];
				//		if (b is overlap)
				//		{
				//			vars.onladder = true;
				//			break;
				//		}
				//	}
				//}
			}
		}
	}

	// ladder sector

	if (this.getMap().getSectorAtPosition(this.getPosition(), "ladder") !is null)
	{
		vars.onladder = true;
	}
}
