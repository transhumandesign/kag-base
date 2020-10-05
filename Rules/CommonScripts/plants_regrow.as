#define SERVER_ONLY

const bool moss_stone = false; //should stone turn into mossy stone

const f32 grass_grow_chance = 10;
const f32 bush_grow_chance = 1;
const f32 moss_stone_chance = 2;

const u32 moss_time_min = 300*30*30; //10 minutes = 300*30*30

u8 random_time = 120;

TileInfo@[] tiles;

class TileInfo
{
	Vec2f coords;
	u32 place_time;
	Tile tile;

	TileInfo() {};

	TileInfo(Vec2f _coords, u32 _place_time, Tile _tile)
	{
		coords = _coords;
		place_time = _place_time;
		tile = _tile;
	};

	bool mossTime()
	{
		return (getGameTime() - place_time > moss_time_min);
	}

	u8 grassLuck()
	{
		u8 luck = 0;
		CMap@ map = getMap();

		Tile tile_left = map.getTile(coords-Vec2f(map.tilesize, map.tilesize));
		Tile tile_right = map.getTile(coords-Vec2f(-map.tilesize, map.tilesize));

		if (tile_left.type == CMap::tile_grass) luck += 15;
		if (tile_right.type == CMap::tile_grass) luck += 15;

		return luck;
	}

	u8 mossLuck()
	{
		u8 luck = 0;
		CMap@ map = getMap();

		Tile tile_left = map.getTile(coords - Vec2f(map.tilesize, 0));
		Tile tile_right = map.getTile(coords - Vec2f(-map.tilesize, 0));
		Tile tile_above = map.getTile(coords - Vec2f(0, map.tilesize));
		Tile tile_below = map.getTile(coords - Vec2f(0, -map.tilesize));

		if (map.isTileGround(tile_below.type) || map.isTileBedrock(tile_below.type) || tile_below.type == CMap::tile_castle_moss || tile_below.type == CMap::tile_castle_back_moss) {luck += 2;}
		if (map.isTileGround(tile_above.type) || map.isTileBedrock(tile_above.type) || tile_above.type == CMap::tile_castle_moss || tile_above.type == CMap::tile_castle_back_moss) {luck += 2;}
		if (map.isTileGround(tile_left.type) || map.isTileBedrock(tile_left.type) || tile_left.type == CMap::tile_castle_moss || tile_left.type == CMap::tile_castle_back_moss) {luck += 2;}
		if (map.isTileGround(tile_right.type) || map.isTileBedrock(tile_right.type) || tile_right.type == CMap::tile_castle_moss || tile_right.type == CMap::tile_castle_back_moss) {luck += 2;}

		return luck;
	}
};

void onInit(CRules@ this)
{
	CMap@ map = getMap();
	if (map!is null)
	{
		tiles.insertLast(TileInfo(Vec2f(-1,-1), 0, map.getTile(Vec2f(0,0))));
		for (u32 x = 0; x < map.tilemapwidth; x++)
		{
			for (u32 y = 0; y < map.tilemapheight; y++)
			{
				Vec2f coords(x*map.tilesize, y*map.tilesize);

				Tile tile = map.getTile(coords);
				Tile tile_left = map.getTile(coords-Vec2f(map.tilesize, 0));
				Tile tile_right = map.getTile(coords-Vec2f(-map.tilesize, 0));
				Tile tile_above = map.getTile(coords-Vec2f(0, map.tilesize));
				Tile tile_below = map.getTile(coords-Vec2f(0, -map.tilesize));

				if (map.isTileGround(tile.type) && (tile_above.type == CMap::tile_empty || (map.isTileBackground(tile_above) && tile_above.type != CMap::tile_ground_back))) 
					tiles.insertLast(TileInfo(coords, 0, tile)); //add if there's castle/wood wall above dirt so grass grows after its destroyed

				if (tile.type == CMap::tile_castle || tile.type == CMap::tile_castle_back) 
					tiles.insertLast(TileInfo(coords, 0, tile));
			}
		}
		if (!map.hasScript("grow.as")) map.AddScript("grow.as");
	}

}

void onRestart(CRules@ this)
{
	CMap@ map = getMap();
	tiles.clear();

	if (map !is null)
	{
		if (!map.hasScript("grow.as")) map.AddScript("grow.as");
	}
	onInit(this);
}

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
		
	u32 x = index % this.tilemapwidth;
	u32 y = index / this.tilemapwidth;
	
	Vec2f coords(x*this.tilesize,y*this.tilesize);

	u32 tindex = findTileByCoords(tiles, coords);

	if ((newtile == CMap::tile_castle || newtile == CMap::tile_castle_back) && tindex == 0) 
		tiles.insertLast(TileInfo(coords, getGameTime(), this.getTile(coords)));
	else
	{
		print("tindex "+tindex);
		if (this.isTileGround(oldtile)) tiles.removeAt(tindex);
		if (oldtile == CMap::tile_castle || oldtile == CMap::tile_castle_back) tiles.removeAt(tindex);
	}
}

u32 findTileByCoords(TileInfo@[] tiles, Vec2f coords)
{
	for (u32 i = 1; i < tiles.length; i++)
	{
		TileInfo tile = tiles[i];
		if (tile.coords == coords) return i;
	}

	return 0;
}

void onTick(CRules@ this)
{		
	if (getGameTime() % random_time == 0)
	{
		CMap@ map = getMap();
		float tilesize = map.tilesize;

		for (int i = 1; i < tiles.length(); i++)
		{
			TileInfo tinfo = tiles[i];
			if (tinfo is null) return;

			f32 random_grow = XORRandom(1000) / 10;

			if (map.isTileGround(tinfo.tile.type))
			{
				if (random_grow - tinfo.grassLuck() <= grass_grow_chance && map.getTile(tinfo.coords - Vec2f(0,tilesize)).type == CMap::tile_empty)
				{
					map.server_SetTile(tinfo.coords - Vec2f(0, tilesize), CMap::tile_grass + XORRandom(3));
				}

				random_grow = XORRandom(1000)/10;

				if (random_grow <= bush_grow_chance && map.getTile(tinfo.coords - Vec2f(0,tilesize)).type == CMap::tile_empty)
				{
					CBlob@[] blobs;
					bool near_bush = false;
					if (map.getBlobsInRadius(tinfo.coords, 8.0f, blobs))
					{
						for (int a = 0; a<blobs.length(); a++)
						{
							CBlob@ blob = blobs[a];
							if (blob is null) continue;
							if (blob.getName() == "bush")
							{
								near_bush = true; 
								break;
							}
						}
					}
					if (!near_bush) server_CreateBlob("bush", -1, tinfo.coords - Vec2f(0,tilesize));
				}
			}

			random_grow = XORRandom(1000) / 10;

			if ((tinfo.tile.type == CMap::tile_castle || tinfo.tile.type == CMap::tile_castle_back) && moss_stone)
			{
				if (tinfo.mossLuck() > 0 && random_grow - tinfo.mossLuck() <= moss_stone_chance && tinfo.mossTime())
				{
					if (tinfo.tile.type == CMap::tile_castle) map.server_SetTile(tinfo.coords,CMap::tile_castle_moss);
					if (tinfo.tile.type == CMap::tile_castle_back) map.server_SetTile(tinfo.coords,CMap::tile_castle_back_moss);
				}
			}
		}

		random_time = 100 + XORRandom(60);
	}
}
