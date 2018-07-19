///Minimap Code
// Almost 100% accurately replicates the legacy minimap drawer
// This is due to it being a port of the legacy code, provided by Geti

void CalculateMinimapColour( CMap@ map, u32 offset, TileType tile, SColor &out col)
{
	int X = offset % map.tilemapwidth;
	int Y = offset/map.tilemapwidth;
	
	Vec2f pos = Vec2f(X,Y);
	
	Tile ctile = map.getTile(pos*8);
	
	///Colours
	
	u32 color_minimap_solid_edge = 0xff844715;
	u32 color_minimap_solid = 0xffc4873a;
	u32 color_minimap_back_edge = 0xffc4873a; //yep, same as above
	u32 color_minimap_back = 0xfff3ac5c;
	u32 color_minimap_open = 0x00edcca6;
	SColor color_minimap_gold = SColor(255,252,184,44);
	SColor color_minimap_gold_edge = SColor(255,252,146,1);
	
	///Get's the correct colour
	
	if (map.isTileGround( tile ) || map.isTileStone( tile ) ||
        map.isTileBedrock( tile ) || map.isTileThickStone( tile ) ||
        map.isTileCastle( tile ) || map.isTileWood( tile ) )
	{
		col = color_minimap_solid; //Foreground
		
		if (X != 0 && Y != 0 && X < map.tilemapwidth && Y < map.tilemapheight)
		{
			if(isForegroundOutlineTile(map.getTile(pos*8 + Vec2f(0,8))) || isForegroundOutlineTile(map.getTile(pos*8 + Vec2f(0,-8))) 
			|| isForegroundOutlineTile(map.getTile(pos*8 + Vec2f(8,0))) || isForegroundOutlineTile(map.getTile(pos*8 + Vec2f(-8,0))))
			{
				col = color_minimap_solid_edge; //Foreground edge
			}
		}
	}
	else if(map.isTileBackground(ctile) && !map.isTileGrass(tile))
	{
		col = color_minimap_back; //Background
		
		if (X != 0 && Y != 0 && X < map.tilemapwidth && Y < map.tilemapheight)
		{
			if(isBackgroundOutlineTile(map.getTile(pos*8 + Vec2f(0,8))) || isBackgroundOutlineTile(map.getTile(pos*8 + Vec2f(0,-8))) 
			|| isBackgroundOutlineTile(map.getTile(pos*8 + Vec2f(8,0))) || isBackgroundOutlineTile(map.getTile(pos*8 + Vec2f(-8,0))))
			{
				col = color_minimap_back_edge; //Background edge
			}
		}
	}
	else if(map.isTileGold(tile))
	{
		col = color_minimap_gold; //Gold
		
		if (X != 0 && Y != 0 && X < map.tilemapwidth && Y < map.tilemapheight)
		{
			if(!map.isTileSolid(map.getTile(pos*8 + Vec2f(0,8))) || !map.isTileSolid(map.getTile(pos*8 + Vec2f(0,-8))) 
			|| !map.isTileSolid(map.getTile(pos*8 + Vec2f(8,0))) || !map.isTileSolid(map.getTile(pos*8 + Vec2f(-8,0))))
			{
				col = color_minimap_gold_edge; //Gold edge
			}
		}
	}
	else
	{
		col = color_minimap_open; //Sky
	}

	
	///Tints the world based on Fire/Water State
	
	const SColor color_minimap_water(0xff2cafde);
	const SColor color_minimap_fire(0xffd5543f);

	if (map.isInWater( pos*8 ) )
	{
		col = col.getInterpolated(color_minimap_water,0.5f);
	}
	else if (map.isInFire( pos*8 ) )
	{
		col = col.getInterpolated(color_minimap_fire,0.5f);
	}
}

bool isForegroundOutlineTile(Tile tile){

	return !getMap().isTileSolid(tile) || getMap().isTileGold(tile.type);

}

bool isBackgroundOutlineTile(Tile tile){

	return tile.type == CMap::tile_empty || getMap().isTileGold(tile.type);

}