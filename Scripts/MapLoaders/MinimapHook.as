///Minimap Code

void CalculateMinimapColour( CMap@ map, u32 offset, TileType tile, SColor &out col)
{
	int X = offset % map.tilemapwidth;
	int Y = offset / map.tilemapwidth;

	Vec2f pos = Vec2f(X, Y);

	float ts = map.tilesize;
	Tile ctile = map.getTile(pos * ts);

	bool show_gold = getRules().get_bool("show_gold");

	///Colours
	const SColor color_minimap_open         (0xffA5BDC8);
	const SColor color_minimap_ground       (0xff844715);
	const SColor color_minimap_back         (0xff3B1406);
	const SColor color_minimap_stone        (0xff8B6849);
	const SColor color_minimap_thickstone   (0xff42484B);
	const SColor color_minimap_gold         (0xffFEA53D);
	const SColor color_minimap_bedrock      (0xff2D342D);
	const SColor color_minimap_wood         (0xffC48715);
	const SColor color_minimap_castle       (0xff637160);

	const SColor color_minimap_castle_back  (0xff313412);
	const SColor color_minimap_wood_back    (0xff552A11);

	const SColor color_minimap_water        (0xff2cafde);
	const SColor color_minimap_fire         (0xffd5543f);
	
	if (show_gold && map.isTileGold(tile))  { 
		col = color_minimap_gold;
	} 
	else if (map.isTileGround(tile))
	{
		col = color_minimap_ground;
	}
	else if (map.isTileThickStone(tile))
	{
		col = color_minimap_thickstone;
	}
	else if (map.isTileStone(tile))
	{
		col = color_minimap_stone;
	}
	else if (map.isTileBedrock(tile))
	{
		col = color_minimap_bedrock;
	}
	else if (map.isTileWood(tile)) 
	{ 
		col = color_minimap_wood;
	} 
	else if (map.isTileCastle(tile))      
	{ 
		col = color_minimap_castle;
	} 
	else if (map.isTileBackgroundNonEmpty(ctile) && !map.isTileGrass(tile)) {
		
		// TODO(hobey): maybe check if there's a door/platform on this backwall and make a custom color for them?
		if (tile == CMap::tile_castle_back) 
		{ 
			col = color_minimap_castle_back;
		} 
		else if (tile == CMap::tile_wood_back)   
		{ 
			col = color_minimap_wood_back;
		} 
		else                                     
		{ 
			col = color_minimap_back;
		}
		
	} 
	else 
	{
		col = color_minimap_open;
	}
	
	///Tint the map based on Fire/Water State
	if (map.isInWater( pos * ts ))
	{
		col = col.getInterpolated(color_minimap_water,0.5f);
	}
	else if (map.isInFire( pos * ts ))
	{
		col = col.getInterpolated(color_minimap_fire,0.5f);
	}
}

//(avoid conflict with any other functions)
namespace MiniMap
{
	Vec2f clampInsideMap(Vec2f pos, CMap@ map)
	{
		return Vec2f(
			Maths::Clamp(pos.x, 0, (map.tilemapwidth - 0.1f) * map.tilesize),
			Maths::Clamp(pos.y, 0, (map.tilemapheight - 0.1f) * map.tilesize)
		);
	}

	bool isForegroundOutlineTile(Tile tile, CMap@ map)
	{
		return !map.isTileSolid(tile);
	}

	bool isOpenAirTile(Tile tile, CMap@ map)
	{
		return tile.type == CMap::tile_empty ||
			map.isTileGrass(tile.type);
	}

	bool isBackgroundOutlineTile(Tile tile, CMap@ map)
	{
		return isOpenAirTile(tile, map);
	}

	bool isGoldOutlineTile(Tile tile, CMap@ map, bool is_gold)
	{
		return is_gold ?
			!map.isTileSolid(tile.type) :
			map.isTileGold(tile.type);
	}

	//setup the minimap as required on server or client
	void Initialise()
	{
		CRules@ rules = getRules();
		CMap@ map = getMap();

		//add sync script
		//done here to avoid needing to modify gamemode.cfg
		if (!rules.hasScript("MinimapSync.as"))
		{
			rules.AddScript("MinimapSync.as");
		}

		//init appropriately
		if (isServer())
		{
			//load values from cfg
			ConfigFile cfg();
			cfg.loadFile("Base/Rules/MinimapSettings.cfg");

			map.legacyTileMinimap = cfg.read_bool("legacy_minimap", false);
			bool show_gold = cfg.read_bool("show_gold", true);

			//write out values for serialisation
			rules.set_bool("legacy_minimap", map.legacyTileMinimap);
			rules.set_bool("show_gold", show_gold);
		}
		else
		{
			//write defaults for now
			map.legacyTileMinimap = false;
			rules.set_bool("show_gold", true);
		}
	}
}