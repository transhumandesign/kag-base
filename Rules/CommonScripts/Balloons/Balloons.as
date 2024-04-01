#define CLIENT_ONLY

TileInfo@[] solid_tiles;

u32 max_random_inc 	= 15;
u32 min_random_time = 6;
u32 next_check_time = 30;

CParticle@[] particles_array;

class TileInfo
{
	Vec2f coords;
	Tile tile;

	TileInfo() {};

	TileInfo(Vec2f _coords, u32 _place_time, Tile _tile)
	{
		coords = _coords;
		tile = _tile;
	};
};

void onInit(CRules@ this)
{
	CMap@ map = getMap();
	if (map !is null)
	{
		// add fake tile to the start of TileInfo arrays so if findTileByCoords returns 0 it doesn't refer to a tile we should've updated
		solid_tiles.insertLast(TileInfo(Vec2f(-1,-1), 0, map.getTile(Vec2f(0,0))));

		for (u32 x = 0; x < map.tilemapwidth; x++)
		{
			for (u32 y = 0; y < map.tilemapheight; y++)
			{
				Vec2f coords(x * map.tilesize, y * map.tilesize);

				Tile tile = map.getTile(coords);
				Tile tile_below = map.getTile(coords + Vec2f(0, map.tilesize));

				// add any solid tiles
				if (map.isTileSolid(tile))
				{
					solid_tiles.insertLast(TileInfo(coords, 0, tile));
				}
			}
		}

		if (!map.hasScript("Balloons.as")) map.AddScript("Ballonons.as"); // adding map scripts from CRules is much more convenient than adding it to every map in mapcycle.cfg
	}
}

void onRestart(CRules@ this)
{
	next_check_time = min_random_time;
	
	// refill TileInfo arrays with info for the newly loaded map
	solid_tiles.clear();
	onInit(this);
}

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
	u32 x = index % this.tilemapwidth;
	u32 y = index / this.tilemapwidth;
	Vec2f coords(x * this.tilesize, y * this.tilesize);
	u32 tindex = findTileByCoords(solid_tiles, coords);
	
	// remove if tile is not solid anymore
	if (this.isTileSolid(oldtile) && !this.isTileSolid(newtile) && tindex != 0 && solid_tiles.size() > 0)
	{
		solid_tiles.removeAt(tindex);
	}

	// new tile, add it if it's solid
	if (tindex == 0 && this.isTileSolid(newtile))
	{
		solid_tiles.insertLast(TileInfo(coords, getGameTime(), this.getTile(coords))); 
	}
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

bool onMapTileCollapse(CMap@ this, u32 offset)
{
	Vec2f pos = this.getTileWorldPosition(offset);
	u32 tindex_castle = findTileByCoords(solid_tiles, pos);
	
	// tile collapsed, remove from array
	if (tindex_castle != 0 && solid_tiles.size() > 0)
	{
		solid_tiles.removeAt(tindex_castle);
	}
	return true;
}

void onTick(CRules@ this)
{	
	// create new particle
	if (getGameTime() >= next_check_time)
	{
		CMap@ map = getMap();
		float tilesize = map.tilesize;

		if (solid_tiles.size() == 0) return;

		TileInfo tinfo = solid_tiles[XORRandom(solid_tiles.size() - 1)];
		if (tinfo is null) return;

		// particles
			
		f32 offset_x = XORRandom(64) - 32;

		CParticle@ p = ParticleAnimated(
		"BalloonParticle" + XORRandom(6) + ".png", 			// file name
		tinfo.coords, 										// position
		getRandomVelocity(0, (XORRandom(3) - 1) * 0.08f, 0), // velocity
		0, 													// rotation
		1.0f, 												// scale
		6,													// ticks per frame
		-0.0065f,											// gravity
		false);												// self lit
	
		if (p !is null)
		{
			p.AddDieFunction("Balloons.as", "BalloonPop");
			particles_array.insertLast(p);
			//print("particle created - array: " + particles_array.size());
		}

		next_check_time = getGameTime() + min_random_time + XORRandom(max_random_inc);
	}
	
	// manage existing particles
	for (u32 i = 1; i < particles_array.size(); i++)
	{
		CParticle@ array_p = particles_array[i];
		
		if (array_p !is null)
		{
			// kill it if it reaches top, otherwise keep extending its lifetime
			if (array_p.tilepos.y < 8 && array_p.frame < 19)
			{
				array_p.frame = 19;
			}
			else if (array_p.tilepos.y > 8 && array_p.frame > 19)
			{
				array_p.frame = 0;
			}
			
			// change x velocity slightly
			if (XORRandom(100) == 0) 
			{
				uint change_amount = (10 - XORRandom(20)) * 0.06f;
				f32 new_x = Maths::Max(Maths::Min(array_p.velocity.x + change_amount, 1), -1); // no more than 1 and no less than -1
				array_p.velocity = Vec2f(new_x, array_p.velocity.y);
			}
		}
	}
}

void BalloonPop(CParticle@ p)
{
	Sound::Play("BalloonPop.ogg", p.position);
	
	u32 particle_index = Find(particles_array, p);
	if (particle_index != -1)
	{
		particles_array.removeAt(particle_index);
	}
	//print("particle died - array: " + particles_array.size());
}

u32 Find(CParticle@[] particles_array, CParticle@ p)
{
	for (u32 i = 1; i < particles_array.size(); i++)
	{
		CParticle@ array_p = particles_array[i];
		
		if (array_p !is null && p !is null && array_p is p)
		{
			return i;
		}
	}
	
	return -1;
}
