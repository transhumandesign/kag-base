///Minimap Code
// Almost 100% accurately replicates the legacy minimap drawer
// This is due to it being a port of the legacy code, provided by Geti

void CalculateMinimapColour( CMap@ map, u32 offset, TileType tile, SColor &out col)
{
	int X = offset % map.tilemapwidth;
	int Y = offset/map.tilemapwidth;

	Vec2f pos = Vec2f(X, Y);

	float ts = map.tilesize;
	Tile ctile = map.getTile(pos * ts);

	///Colours

	const SColor color_minimap_solid_edge(0xff844715);
	const SColor color_minimap_solid     (0xffc4873a);
	const SColor color_minimap_back_edge (0xffc4873a); //yep, same as above
	const SColor color_minimap_back      (0xfff3ac5c);
	const SColor color_minimap_open      (0x00edcca6);
	const SColor color_minimap_gold      (0xfffbaa00);
	const SColor color_minimap_gold_edge (0xffb15d18);

	const SColor color_minimap_water     (0xff2cafde);
	const SColor color_minimap_fire      (0xffd5543f);

	//neighbours
	Tile tile_l = map.getTile(clampInsideMap(pos * ts - Vec2f(ts, 0), map));
	Tile tile_r = map.getTile(clampInsideMap(pos * ts + Vec2f(ts, 0), map));
	Tile tile_u = map.getTile(clampInsideMap(pos * ts - Vec2f(0, ts), map));
	Tile tile_d = map.getTile(clampInsideMap(pos * ts + Vec2f(0, ts), map));

	///figure out the correct colour
	if (map.isTileGround( tile ) || map.isTileStone( tile ) ||
        map.isTileBedrock( tile ) || map.isTileThickStone( tile ) ||
        map.isTileCastle( tile ) || map.isTileWood( tile ) )
	{
		//Foreground
		col = color_minimap_solid;

		//Edge
		if( isForegroundOutlineTile(tile_u, map) || isForegroundOutlineTile(tile_d, map) ||
		    isForegroundOutlineTile(tile_l, map) || isForegroundOutlineTile(tile_r, map) )
		{
			col = color_minimap_solid_edge;
		}
		else if( isGoldOutlineTile(tile_u, map, false) || isGoldOutlineTile(tile_d, map, false) ||
		         isGoldOutlineTile(tile_l, map, false) || isGoldOutlineTile(tile_r, map, false) )
		{
			col = color_minimap_gold_edge;
		}
	}
	else if(map.isTileBackground(ctile) && !map.isTileGrass(tile))
	{
		//Background
		col = color_minimap_back;

		//Edge
		if( isBackgroundOutlineTile(tile_u, map) || isBackgroundOutlineTile(tile_d, map) ||
		    isBackgroundOutlineTile(tile_l, map) || isBackgroundOutlineTile(tile_r, map) )
		{
			col = color_minimap_back_edge;
		}
	}
	else if(map.isTileGold(tile))
	{
		//Gold
		col = color_minimap_gold;

		//Edge
		if( isGoldOutlineTile(tile_u, map, true) || isGoldOutlineTile(tile_d, map, true) ||
		    isGoldOutlineTile(tile_l, map, true) || isGoldOutlineTile(tile_r, map, true) )
		{
			col = color_minimap_gold_edge;
		}
	}
	else
	{
		//Sky
		col = color_minimap_open;
	}

	///Tint the map based on Fire/Water State
	if (map.isInWater( pos * ts ) )
	{
		col = col.getInterpolated(color_minimap_water,0.5f);
	}
	else if (map.isInFire( pos * ts ) )
	{
		col = col.getInterpolated(color_minimap_fire,0.5f);
	}
}

Vec2f clampInsideMap(Vec2f pos, CMap@ map)
{
	return Vec2f(
		Maths::Clamp(pos.x, 0, map.tilemapwidth * map.tilesize),
		Maths::Clamp(pos.y, 0, map.tilemapheight * map.tilesize)
	);
}

bool isForegroundOutlineTile(Tile tile, CMap@ map)
{
	return !map.isTileSolid(tile);
}

bool isBackgroundOutlineTile(Tile tile, CMap@ map)
{
	return tile.type == CMap::tile_empty ||
		map.isTileGrass(tile.type) ||
		map.isTileGold(tile.type);
}

bool isGoldOutlineTile(Tile tile, CMap@ map, bool is_gold)
{
	return is_gold ?
		!map.isTileSolid(tile) :
		map.isTileGold(tile.type);
}