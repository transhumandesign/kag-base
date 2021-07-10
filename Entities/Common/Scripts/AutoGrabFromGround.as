// set what it grabs with
// this.set_string("autograb blob", "mat_bolts")

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 89; // opt

	string[] autograb_blob_names;

	if (!this.exists("autograb blobs"))
		this.set("autograb blobs", autograb_blob_names);
}

void onTick(CBlob@ this)
{
	CBlob@[] blobsInRadius;
	if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() * 1.1f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];

			string[] autograb_blobs;
			this.get("autograb blobs", autograb_blobs);

			if (b.isOnGround() && !b.isAttached() && autograb_blobs.find(b.getName()) != -1)
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
