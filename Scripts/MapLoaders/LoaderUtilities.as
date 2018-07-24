// LoaderUtilities.as

#include "DummyCommon.as";

void onInit(CMap@ this)
{
	this.MakeMiniMap();
}

bool onMapTileCollapse(CMap@ map, u32 offset)
{
	if(isDummyTile(map.getTile(offset).type))
	{
		CBlob@ blob = getBlobByNetworkID(server_getDummyGridNetworkID(offset));
		if(blob !is null)
		{
			blob.server_Die();
		}
	}
	return true;
}

void CalculateMinimapColour( CMap@ this, u32 offset, TileType tile, SColor &out col)
{
    SColor GoldColor = SColor(0xffFC613F);	//gold color, that will be seen on minimap
	
	if (this.isTileSolid(this.getTile(offset)))
	{
		if (this.isTileGold(tile))
			col = GoldColor;
		else if ((!this.isTileSolid(this.getTile(offset-1)) || this.isTileGold(this.getTile(offset-1).type)) ||
			(!this.isTileSolid(this.getTile(offset+1)) || this.isTileGold(this.getTile(offset+1).type)) ||
			(!this.isTileSolid(this.getTile(offset-this.tilemapwidth)) || this.isTileGold(this.getTile(offset-this.tilemapwidth).type)) ||
			(!this.isTileSolid(this.getTile(offset+this.tilemapwidth)) || this.isTileGold(this.getTile(offset+this.tilemapwidth).type)))
			col = SColor(0xff844715);
		else
			col = SColor(0xffC4873A);
	}
	else if (!this.isTileSolid(this.getTile(offset)) && tile != 0 && !this.isTileGrass(tile))
	{
		if( (this.getTile(offset-1).type == 0) || 
			(this.getTile(offset+1).type == 0) || 
			(this.getTile(offset-this.tilemapwidth).type == 0) || 
			(this.getTile(offset+this.tilemapwidth).type == 0))
				col = SColor(0xffC4873A);
		else
			col = SColor(0xffF3AC5C);
	}
	else
		col = SColor(0xffEDCCA6);

	if (this.isInWater(this.getTileWorldPosition(offset)))
	{
		col = col.getInterpolated(SColor(255,29,133,171),0.5f);
	}
	else if (this.isInFire(this.getTileWorldPosition(offset)))
	{
		col = col.getInterpolated(SColor(255,239,67,47),0.5f);
	}
}

bool onMapTileCollapse(CMap@ map, u32 offset)
{
	if(isDummyTile(map.getTile(offset).type))
	{
		CBlob@ blob = getBlobByNetworkID(server_getDummyGridNetworkID(offset));
		if(blob !is null)
		{
			blob.server_Die();
		}
	}
	return true;
}

/*
TileType server_onTileHit(CMap@ this, f32 damage, u32 index, TileType oldTileType)
{
}
*/

void onSetTile(CMap@ map, u32 index, TileType tile_new, TileType tile_old)
{
	if(isDummyTile(tile_new))
	{
		map.SetTileSupport(index, 10);

		switch(tile_new)
		{
			case Dummy::SOLID:
			case Dummy::OBSTRUCTOR:
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				break;
			case Dummy::BACKGROUND:
			case Dummy::OBSTRUCTOR_BACKGROUND:
				map.AddTileFlag(index, Tile::BACKGROUND | Tile::LIGHT_PASSES | Tile::WATER_PASSES);
				break;
			case Dummy::LADDER:
				map.AddTileFlag(index, Tile::BACKGROUND | Tile::LIGHT_PASSES | Tile::LADDER | Tile::WATER_PASSES);
				break;
			case Dummy::PLATFORM:
				map.AddTileFlag(index, Tile::PLATFORM);
				break;
		}
	}
}
