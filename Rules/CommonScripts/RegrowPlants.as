#define SERVER_ONLY

// should stone turn into mossy stone
const bool moss_stone = true;

// random_growth is randomly set from 0 to 1.0
// don't set values lower than 0.0001
// if you want to prevent a thing from growing at all, set it's chance to -1 rather than 0
const f32 grass_grow_chance = 0.03f;
const f32 bush_grow_chance = 0.006f;
const f32 flower_grow_chance = 0.001f;
const f32 grain_grow_chance = flower_grow_chance + 0.001f; //add flower chance to prevent them from overriding each other
const f32 chicken_grow_chance = 0.002f; // chickens are plants don't @ me
const u8 chicken_limit = 10; 

const f32 moss_stone_chance = 0.004f;

// how many ticks have to pass before stone starts becoming mossy, 10 minutes = 30 * 60 * 10
const u32 moss_time = 30 * 60 * 10;

// which tiles should turn into moss
// tile from castle_stuff will turn into a corresponding tile from castle_moss_stuff
const u16[] castle_stuff = {CMap::tile_castle, CMap::tile_castle_back};
const u16[] castle_moss_stuff = {CMap::tile_castle_moss, CMap::tile_castle_back_moss};
const string[] plants_stuff = {"bush", "flowers", "grain_plant"};

const u16 min_random_time_dirt = 400; // minimal time between growth checks
const u16 max_random_inc_dirt = 120; // maximum random increase to time between growth checks
const u16 min_random_time_castle = 600;
const u16 max_random_inc_castle = 150;

u32 next_check_time_dirt = min_random_time_dirt;
u32 next_check_time_castle = min_random_time_castle;
u16 checks_done_dirt = 0;
u16 checks_done_castle = 0;
u32 dirt_tiles_check_max = 80; // maxiumum amount of dirt tiles checked in one tick
u32 stone_tiles_check_max = 80; // maxiumum amount of castle tiles checked in one tick

TileInfo@[] dirt_tiles;
TileInfo@[] castle_tiles;

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
		return (getGameTime() - place_time > moss_time); // has enough time passed since this tile was placed?
	}

	bool hasMossOrWaterAdjacent()
	{
		CMap@ map = getMap();

		Vec2f[] adjacentTilePos = {
			Vec2f(map.tilesize, 0),   // left
			Vec2f(-map.tilesize, 0),  // right
			Vec2f(0, map.tilesize),   // up
			Vec2f(0, -map.tilesize)   // down
		};

		for (u8 i = 0; i < adjacentTilePos.size(); i++)
		{
			Vec2f offset = coords - adjacentTilePos[i];
			Tile tile = map.getTile(offset);
			u32 index = findTileByCoords(castle_tiles, offset);
			bool water = map.isInWater(offset);
			bool mossyCastle = castle_moss_stuff.find(tile.type) != -1;

			// to ignore min time restriction if tile is close to moss or water, otherwise you can prevent moss from spreading very very easily
			if (water)
			{
				return true;
			}
			else if (mossyCastle)
			{
				TileInfo tinfo = castle_tiles[index];

				if (tinfo.place_time != 0) // prevent moss that was on the map since the beginning from spreading
				{
					return true;
				}
			}
		}

		return false;
	}

	f32 grassLuck()
	{
		f32 luck = 0;
		CMap@ map = getMap();

		Tile tile_left = map.getTile(coords - Vec2f(map.tilesize, map.tilesize));
		Tile tile_right = map.getTile(coords - Vec2f(-map.tilesize, map.tilesize));

		// increase chance that grass will grow on this tile if there's grass around it
		if (map.isTileGrass(tile_left.type))
		{
			luck += 0.15f;
		}

		if (map.isTileGrass(tile_right.type))
		{
			luck += 0.15f;
		}

		return luck;
	}

	f32 mossLuck()
	{
		f32 luck = 0;
		CMap@ map = getMap();

		Vec2f[] adjacentTilePos = {
			Vec2f(map.tilesize, 0),   // left
			Vec2f(-map.tilesize, 0),  // right
			Vec2f(0, map.tilesize),   // up
			Vec2f(0, -map.tilesize)   // down
		};

		for (u8 i = 0; i < adjacentTilePos.size(); i++)
		{
			Vec2f offset = coords - adjacentTilePos[i];
			Tile tile = map.getTile(offset);
			bool ground = map.isTileGround(tile.type);
			bool bedrock = map.isTileBedrock(tile.type);
			bool mossyCastle = castle_moss_stuff.find(tile.type) != -1;
			bool water = map.isInWater(offset);

			// increase chance that this tile will mossify if there's dirt, bedrock, water, or other mossy tiles around it
			if (ground || bedrock || mossyCastle)
			{
				luck += 0.0015f;
			}
			if (water)
			{
				luck += 0.01f;
			}
		}

		return luck;
	}
};

void onInit(CRules@ this)
{
	CMap@ map = getMap();
	if (map !is null)
	{
		// add fake tiles to the start of TileInfo arrays so if findTileByCoords returns 0 it doesn't refer to a tile we should've updated
		dirt_tiles.insertLast(TileInfo(Vec2f(-1,-1), 0, map.getTile(Vec2f(0,0))));
		castle_tiles.insertLast(TileInfo(Vec2f(-1,-1), 0, map.getTile(Vec2f(0,0))));
		for (u32 x = 0; x < map.tilemapwidth; x++)
		{
			for (u32 y = 0; y < map.tilemapheight; y++)
			{
				Vec2f coords(x * map.tilesize, y * map.tilesize);

				Tile tile = map.getTile(coords);
				Tile tile_above = map.getTile(coords - Vec2f(0, map.tilesize));

				// add tile if tile above it is empty or it's a castle/wood wall so grass grows after it's destroyed
				bool valid_back = (tile_above.type == CMap::tile_empty || (map.isTileBackground(tile_above) && tile_above.type != CMap::tile_ground_back));

				if (map.isTileGround(tile.type) && valid_back)
				{
					dirt_tiles.insertAt(Maths::XORRandom(dirt_tiles.size()), TileInfo(coords, 0, tile));
				}

				// add stuff from castle_stuff into its own array
				if (castle_stuff.find(tile.type) != -1) 
				{
					castle_tiles.insertAt(Maths::XORRandom(castle_tiles.size()), TileInfo(coords, 0, tile));
				}
			}
		}

		if (!map.hasScript("RegrowPlants.as")) map.AddScript("RegrowPlants.as"); // adding map scripts from CRules is much more convenient than adding it to every map in mapcycle.cfg
		
		//set the first check time
		u16 factor = getFactorDirt();
		next_check_time_dirt = getGameTime() + Maths::Floor(min_random_time_dirt / factor);
		next_check_time_castle = next_check_time_dirt; // will be checked one tick after dirt
	}
}

void onRestart(CRules@ this)
{
	// refill TileInfo arrays with info for the newly loaded map
	dirt_tiles.clear();
	castle_tiles.clear();
	onInit(this);
}

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
	u32 x = index % this.tilemapwidth;
	u32 y = index / this.tilemapwidth;
	Vec2f coords(x * this.tilesize, y * this.tilesize);
	u32 tindex_dirt = findTileByCoords(dirt_tiles, coords);
	u32 tindex_castle = findTileByCoords(castle_tiles, coords);

	// dirt leaves dirt background after it's destroyed, so no need to check for dirt tiles below it
	// onSetTile runs when a tile is damaged, so check if new tile is just more damaged dirt
	if (this.isTileGround(oldtile) && !this.isTileGround(newtile) && tindex_dirt != 0 && dirt_tiles.size() > 0)
	{
		dirt_tiles.removeAt(tindex_dirt);
	}
	// castle tile got destroyed/damaged/mossified, remove from array
	// don't check if new tile is just a damaged castle, because we don't mossify damaged stone (only full hp stone has moss variants)
	if (castle_stuff.find(oldtile) != -1 && tindex_castle != 0 && castle_tiles.size() > 0)
	{
		castle_tiles.removeAt(tindex_castle);
	}
	// castle tile was built, add to array
	if (castle_stuff.find(newtile) != -1 && tindex_castle == 0)
	{
		castle_tiles.insertAt(Maths::XORRandom(castle_tiles.size()), TileInfo(coords, getGameTime(), this.getTile(coords)));
	}
}

bool onMapTileCollapse(CMap@ this, u32 offset)
{
	Vec2f pos = this.getTileWorldPosition(offset);
	u32 tindex_castle = findTileByCoords(castle_tiles, pos);
	
	// castle tile collapsed, remove from array
	if (tindex_castle != 0 && castle_tiles.size() > 0)
	{
		castle_tiles.removeAt(tindex_castle);
	}
	return true;
}

u32 findTileByCoords(const TileInfo@[] &in tiles, Vec2f coords)
{
	for (u32 i = 1; i < tiles.size(); i++)
	{
		if (tiles[i].coords == coords)
		{
			return i;
		}
	}

	return 0;
}

void onTick(CRules@ this)
{	
	if (getGameTime() >= next_check_time_dirt)
	{
		CMap@ map = getMap();
		float tilesize = map.tilesize;

		CBlob@[] chicken_list;
		getBlobsByName("chicken", chicken_list);
		u16 chicken_count = chicken_list.size();
		
		// determining start and end of loop
		u16 factor = getFactorDirt();
		u32 check_start, check_end;
		
		if (checks_done_dirt % factor == 0)
		{	
			check_start = 0;
			check_end = Maths::Floor(dirt_tiles.size() / factor);
		}
		else if (checks_done_dirt % factor == factor - 1)
		{
			check_start = Maths::Floor(dirt_tiles.size() / factor) * (checks_done_dirt % factor) + 1;
			check_end = dirt_tiles.size();
		}
		else 
		{
			check_start = Maths::Floor(dirt_tiles.size() / factor) * (checks_done_dirt % factor) + 1;
			check_end = check_start + Maths::Floor(dirt_tiles.size() / factor);
		}

		// running loop
		for (int i = check_start; i < Maths::Min(check_end, dirt_tiles.size()); i++)
		{
			TileInfo tinfo = dirt_tiles[i];
			if (tinfo is null) return;
			Tile tile_above = map.getTile(tinfo.coords - Vec2f(0, tilesize));

			if (tile_above.type == CMap::tile_empty || map.isTileGrass(tile_above.type))
			{
				f32 random_grow = XORRandom(10000) * 0.0001f;

				// GRASS
				if (random_grow - tinfo.grassLuck() <= grass_grow_chance && !map.isTileGrass(tile_above.type))
				{
					Vec2f tile_position = tinfo.coords - Vec2f(0, tilesize);
					
					CBlob@[] blobs;
					bool dont_grow = false;
					
					// don't grow if burning fireplace is near
					if (map.getBlobsInRadius(tile_position, 8.0f, blobs))
					{
						for (int a = 0; a < blobs.size(); a++)
						{
							CBlob@ blob = blobs[a];
							if (blob is null)
							{
								continue;
							}
							if (blob.getName() == "fireplace" && blob.getSprite().isAnimation("fire"))  
							{
								dont_grow = true; 
								break;
							}
						}
					}
					
					if (!dont_grow)
					{
						map.server_SetTile(tile_position, CMap::tile_grass + XORRandom(3));
					}
				}

				// PLANTS
				random_grow = XORRandom(10000) * 0.0001f; // generate new random_grow for every growth check to prevent situations where either nothing grows or everything grows on one tile

				s16 plant = -1;

				if (random_grow <= bush_grow_chance) plant = 0;
				if (random_grow <= grain_grow_chance) plant = 2;
				if (random_grow <= flower_grow_chance) plant = 1; // do checks out of order so flower overrides grain growth

				if (plant != -1)
				{
					CBlob@[] blobs;
					bool dont_grow = false;

					Vec2f spawn_position = tinfo.coords - Vec2f(0, tilesize);
					
					// don't grow underwater
					if (map.isInWater(spawn_position))
					{
						dont_grow = true;
					}
					// don't grow if plant or burning fireplace nearby
					else if (map.getBlobsInRadius(tinfo.coords, 8.0f, blobs))
					{
						for (int a = 0; a < blobs.size(); a++)
						{
							CBlob@ blob = blobs[a];
							if (blob is null)
							{
								continue;
							}
							
							if (plants_stuff.find(blob.getName()) != -1 || (blob.getName() == "fireplace" && blob.getSprite().isAnimation("fire")))  
							{
								dont_grow = true; 
								break;
							}
						}
					}

					if (!dont_grow)
					{
						server_CreateBlob(plants_stuff[plant], -1, spawn_position);
					}
				}

				// CHICKENS
				random_grow = XORRandom(10000) * 0.0001f;

				if (random_grow <= chicken_grow_chance && chicken_count < chicken_limit)
				{
					Vec2f spawn_position = tinfo.coords - Vec2f(0, tilesize);
				
					if (!map.isBlobInRadius("mine", spawn_position, 32.0f) // don't spawn chicken near mines
						&& !map.isInWater(spawn_position)) // don't spawn chicken inside water	
					{					
						server_CreateBlob("chicken", -1, spawn_position);
						chicken_count++;
					}
				}
			}
		}

		u16 increase = Maths::Floor(max_random_inc_dirt / factor);
		next_check_time_dirt = getGameTime() + Maths::Floor(min_random_time_dirt / factor) + XORRandom(increase);
		checks_done_dirt++;
	}
	else if (getGameTime() >= next_check_time_castle)
	{
		CMap@ map = getMap();
		float tilesize = map.tilesize;

		// determining start and end of loop
		u16 factor = getFactorCastle();
		u32 check_start, check_end;
		
		if (checks_done_castle % factor == 0)
		{	
			check_start = 0;
			check_end = Maths::Floor(castle_tiles.size() / factor);
		}
		else if (checks_done_castle % factor == factor - 1)
		{
			check_start = Maths::Floor(castle_tiles.size() / factor) * (checks_done_castle % factor) + 1;
			check_end = castle_tiles.size();
		}
		else 
		{
			check_start = Maths::Floor(castle_tiles.size() / factor) * (checks_done_castle % factor) + 1;
			check_end = check_start + Maths::Floor(castle_tiles.size() / factor);
		}
	
		// MOSSIFICATION
		if (moss_stone)
		{
			for (int i = check_start; i < Maths::Min(check_end, castle_tiles.size()); i++)
			{
				TileInfo tinfo = castle_tiles[i];
				f32 random_grow = XORRandom(10000) * 0.0001f;
				u32 ttype = castle_stuff.find(tinfo.tile.type);
				f32 luck = tinfo.mossLuck();
				
				if (ttype != -1)
				{
					//  check for luck being non-zero so stone structures get mossified starting from ground level
					if (luck > 0 && random_grow - luck <= moss_stone_chance && (tinfo.mossTime() || tinfo.hasMossOrWaterAdjacent()))
					{
						map.server_SetTile(tinfo.coords, castle_moss_stuff[ttype]);
					}
				}
			}
		}
		
		u16 increase = Maths::Floor(max_random_inc_castle / factor);
		next_check_time_castle = getGameTime() + Maths::Floor(min_random_time_castle / factor) + XORRandom(increase);
		checks_done_castle++;
	}
}

u16 getFactorDirt()
{
	return Maths::Floor(dirt_tiles.size() / dirt_tiles_check_max) + 1;
}

u16 getFactorCastle()
{
	return Maths::Floor(castle_tiles.size() / dirt_tiles_check_max) + 1;
}
