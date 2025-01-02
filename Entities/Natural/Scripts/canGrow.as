//common "can a plant grow at this tile" code

bool isNotBlockedByOthers(CBlob@ this)
{
	CBlob@[] blobsInRadius;
	CMap@ map = getMap();

	if (map.getBlobsInRadius(this.getPosition(), map.tilesize / 4, @blobsInRadius))
	{
		u16 lowest_net_id = this.getNetworkID();
		bool found_seed = false;
	
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob@ blob = blobsInRadius[i];

			if (blob.getName() == "seed")
			{
				found_seed = true;

				u16 blob_net_id = blob.getNetworkID();
				if (blob_net_id < lowest_net_id)
				{
					lowest_net_id = blob_net_id;
				}
			}
			else if (blob.getName().find("tree") == -1)
			{
				return false;
			}
		}
		
		if (found_seed)
		{
			CBlob@ seed_to_grow = getBlobByNetworkID(lowest_net_id);
			if (seed_to_grow !is null)
			{
				return (seed_to_grow is this);
			}
		}
	}

	return true;
}

bool canGrowAt(CBlob@ this, Vec2f pos)
{
	if (!this.getShape().isStatic()) // they can be static from grid placement
	{
		if (!this.isOnGround() || this.isInWater() || this.isAttached() || !isNotBlockedByOthers(this))
		{
			return false;
		}
	}

	CMap@ map = getMap();

	/*if ( map.isTileGrass( map.getTile( pos ) )) {
	return false;
	}*/   // waiting for better days

	if (map.getSectorAtPosition(pos, "no build") !is null)
	{
		return false;
	}

	// this block of code causes a crash
	/*CBlob@[] blobs;
	map.getBlobsFromTile(map.getTile(pos), blobs);
	for (uint i = 0; i < blobs.length; i++)
	{
		CBlob@ b = blobs[i];
		string bname = b.getName();
		if ((b.isCollidable() ||
			bname == "wooden_door" ||
			bname == "stone_door"))
			return false;

	}*/

	Vec2f underneath = Vec2f(pos.x, pos.y + (this.getHeight() + map.tilesize) * 0.5f);
	return (map.isTileGround(map.getTile(underneath).type));
}
