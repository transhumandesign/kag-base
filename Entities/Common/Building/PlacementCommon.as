
const f32 MAX_BUILD_LENGTH = 4.0f;

shared class BlockCursor
{
	Vec2f tileAimPos;
	bool cursorClose;
	bool buildable;
	bool supported;
	bool hasReqs;
	// for gui
	bool rayBlocked;
	bool buildableAtPos;
	Vec2f rayBlockedPos;
	bool blockActive;
	bool blobActive;
	bool sameTileOnBack;
	CBitStream missing;

	BlockCursor()
	{
		blobActive = blockActive = buildableAtPos = rayBlocked = hasReqs = supported = buildable = cursorClose = sameTileOnBack = false;
	}
};

void AddCursor(CBlob@ this)
{
	if (!this.exists("blockCursor"))
	{
		BlockCursor bc;
		this.set("blockCursor", bc);
	}
}

bool canPlaceNextTo(CMap@ map, const Tile &in tile)
{
	return tile.support > 0;
}

bool isBuildableAtPos(CBlob@ this, Vec2f p, TileType buildTile, CBlob @blob, bool &out sameTile)
{
	f32 radius = 0.0f;
	CMap@ map = this.getMap();
	sameTile = false;

	if (blob is null) // BLOCKS
	{
		radius = map.tilesize;
	}
	else // BLOB
	{
		radius = blob.getRadius();
	}

	//check height + edge proximity
	if (p.y < 2 * map.tilesize ||
	        p.x < 2 * map.tilesize ||
	        p.x > (map.tilemapwidth - 2.0f)*map.tilesize)
	{
		return false;
	}

	// tilemap check
	const bool buildSolid = (map.isTileSolid(buildTile) || (blob !is null && blob.isCollidable()));
	Vec2f tilespace = map.getTileSpacePosition(p);
	const int offset = map.getTileOffsetFromTileSpace(tilespace);
	Tile backtile = map.getTile(offset);
	Tile left = map.getTile(offset - 1);
	Tile right = map.getTile(offset + 1);
	Tile up = map.getTile(offset - map.tilemapwidth);
	Tile down = map.getTile(offset + map.tilemapwidth);

	if (buildTile > 0 && buildTile < 255 && blob is null && buildTile == map.getTile(offset).type)
	{
		sameTile = true;
		return false;
	}

	if ((buildTile == CMap::tile_wood && backtile.type >= CMap::tile_wood_d1 && backtile.type <= CMap::tile_wood_d0) ||
	        (buildTile == CMap::tile_castle && backtile.type >= CMap::tile_castle_d1 && backtile.type <= CMap::tile_castle_d0))
	{
		//repair like tiles
	}
	else if (backtile.type == CMap::tile_wood && buildTile == CMap::tile_castle)
	{
		// can build stone on wood, do nothing
	}
	else if (buildTile == CMap::tile_wood_back && backtile.type == CMap::tile_castle_back)
	{
		//cant build wood on stone background
		return false;
	}
	else if (map.isTileSolid(backtile) || map.hasTileSolidBlobs(backtile))
	{
		if (!buildSolid && !map.hasTileSolidBlobsNoPlatform(backtile) && !map.isTileSolid(backtile))
		{
			//skip onwards, platforms don't block backwall
		}
		else
		{
			return false;
		}
	}

//printf("c");
	bool canPlaceOnBackground = ((blob is null) || (blob.getShape().getConsts().support > 0));   // if this is a blob it has to do support - so spikes cant be placed on back

	if (
	    (!canPlaceOnBackground || !map.isTileBackgroundNonEmpty(backtile)) &&      // can put against background
	    !(                                              // can put sticking next to something
	        canPlaceNextTo(map, left) || (canPlaceOnBackground && map.isTileBackgroundNonEmpty(left))  ||
	        canPlaceNextTo(map, right) || (canPlaceOnBackground && map.isTileBackgroundNonEmpty(right)) ||
	        canPlaceNextTo(map, up)   || (canPlaceOnBackground && map.isTileBackgroundNonEmpty(up))    ||
	        canPlaceNextTo(map, down) || (canPlaceOnBackground && map.isTileBackgroundNonEmpty(down))
	    )
	)
	{
		return false;
	}
	// no blocking actors?
	// printf("d");
	if (blob is null || !blob.hasTag("ignore blocking actors"))
	{
		bool isLadder = false;
		bool isSpikes = false;
		if (blob !is null)
		{
			const string bname = blob.getName();
			isLadder = bname == "ladder";
			isSpikes = bname == "spikes";
		}

		Vec2f middle = p;

		if (!isLadder && (buildSolid || isSpikes) && map.getSectorAtPosition(middle, "no build") !is null)
		{
			return false;
		}

		//if (blob is null)
		//middle += Vec2f(map.tilesize*0.5f, map.tilesize*0.5f);

		const string name = blob !is null ? blob.getName() : "";
		CBlob@[] blobsInRadius;
		if (map.getBlobsInRadius(middle, buildSolid ? map.tilesize : 0.0f, @blobsInRadius))
		{
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob @b = blobsInRadius[i];
				if (!b.isAttached() && b !is blob)
				{
					if (blob !is null || buildSolid)
					{
						if (b is this)					// this is me
						{
							if (!isSpikes && (b.getPosition() - middle).getLength() <= radius)
							{
								return false;

							}

						}
						else
						{
							Vec2f bpos = b.getPosition();

							const string bname = b.getName();

							bool cantBuild = isBlocking(b);

							// cant place on any other blob
							if (cantBuild &&
							        !b.hasTag("dead") &&
							        !b.hasTag("material") &&
							        !b.hasTag("projectile") &&
							        bname != "bush")
							{
								f32 angle_decomp = Maths::FMod(Maths::Abs(b.getAngleDegrees()), 180.0f);
								bool rotated = angle_decomp > 45.0f && angle_decomp < 135.0f;
								f32 width = rotated ? b.getHeight() : b.getWidth();
								f32 height = rotated ? b.getWidth() : b.getHeight();
								if ((middle.x > bpos.x - width * 0.5f) && (middle.x < bpos.x + width * 0.5f)
								        && (middle.y > bpos.y - height * 0.5f) && (middle.y < bpos.y + height * 0.5f))
								{
									return false;
								}
							}
						}
					}
				}
			}
		}
	}

	return true;
}

bool isBlocking(CBlob@ blob)
{
	string name = blob.getName();
	if (name == "heart" || name == "log" || name == "food" || name == "fishy" || name == "steak" || name == "grain") 
		return false;

	return blob.isCollidable() || blob.getShape().isStatic();
}

void SetTileAimpos(CBlob@ this, BlockCursor@ bc)
{
	// calculate tile mouse pos
	Vec2f pos = this.getPosition();
	Vec2f aimpos = this.getAimPos();
	Vec2f mouseNorm = aimpos - pos;
	f32 mouseLen = mouseNorm.Length();
	const f32 maxLen = MAX_BUILD_LENGTH;
	mouseNorm /= mouseLen;

	if (mouseLen > maxLen * getMap().tilesize)
	{
		f32 d = maxLen * getMap().tilesize;
		Vec2f p = pos + Vec2f(d * mouseNorm.x, d * mouseNorm.y);
		p = getMap().getTileSpacePosition(p);
		bc.tileAimPos = getMap().getTileWorldPosition(p);
	}
	else
	{
		bc.tileAimPos = getMap().getTileSpacePosition(aimpos);
		bc.tileAimPos = getMap().getTileWorldPosition(bc.tileAimPos);
	}

	bc.cursorClose = (mouseLen < getMaxBuildDistance(this));
}

f32 getMaxBuildDistance(CBlob@ this)
{
	return (MAX_BUILD_LENGTH + 0.51f) * getMap().tilesize;
}

void SetupBuildDelay(CBlob@ this)
{
	this.set_u32("build time", getGameTime());
	this.set_u32("build delay", 7);  // move this to builder init
}

bool isBuildDelayed(CBlob@ this)
{
	return (getGameTime() <= this.get_u32("build time"));
}

void SetBuildDelay(CBlob@ this)
{
	SetBuildDelay(this, this.get_u32("build delay"));
}

void SetBuildDelay(CBlob@ this, uint time)
{
	this.set_u32("build time", getGameTime() + time);
}

bool isBuildRayBlocked(Vec2f pos, Vec2f target, Vec2f &out point)
{
	CMap@ map = getMap();

	Vec2f vector = target - pos;
	vector.Normalize();
	target -= vector * map.tilesize;

	f32 halfsize = map.tilesize * 0.5f;

	return map.rayCastSolid(pos + Vec2f(0, halfsize), target, point) &&
	       map.rayCastSolid(pos + Vec2f(halfsize, 0), target, point) &&
	       map.rayCastSolid(pos + Vec2f(0, -halfsize), target, point) &&
	       map.rayCastSolid(pos + Vec2f(-halfsize, 0), target, point);
}

