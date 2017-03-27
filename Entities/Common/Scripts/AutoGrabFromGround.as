// set what it grabs with
// this.set_string("autograb blob", "mat_bolts")

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 89; // opt

	if (!this.exists("autograb blob"))
		this.set_string("autograb blob", "");
}

void onTick(CBlob@ this)
{
	CBlob@[] blobsInRadius;
	if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() * 1.1f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b.isOnGround() && !b.isAttached() && b.getName() == this.get_string("autograb blob"))
			{
				this.server_PutInInventory(b);
			}
		}
	}
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().PlaySound("/PopIn");
}
