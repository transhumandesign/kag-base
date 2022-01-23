///Minimap Code
SColor color_sky = SColor(0xffA5BDC8);
SColor color_dirt = SColor(0xff844715);
SColor color_dirt_backwall = SColor(0xff3B1406);
SColor color_stone = SColor(0xff8B6849);
SColor color_thickstone = SColor(0xff42484B);
SColor color_gold = SColor(0xffFEA53D);
SColor color_bedrock = SColor(0xff2D342D);
SColor color_wood = SColor(0xffC48715);
SColor color_wood_backwall = SColor(0xff552A11);
SColor color_castle = SColor(0xff637160);
SColor color_castle_backwall = SColor(0xff313412);
SColor color_water = SColor(0xff2cafde);
SColor color_fire = SColor(0xffd5543f);

void CalculateMinimapColour( CMap@ map, u32 offset, TileType tile, SColor &out col)
{
	int X = offset % map.tilemapwidth;
	int Y = offset / map.tilemapwidth;

	Vec2f pos = Vec2f(X, Y);

	float ts = map.tilesize;
	Tile ctile = map.getTile(pos * ts);

	bool show_gold = getRules().get_bool("show_gold");

	///Colours
	const SColor color_minimap_open         (color_sky);
	const SColor color_minimap_ground       (color_dirt);
	const SColor color_minimap_back         (color_dirt_backwall);
	const SColor color_minimap_stone        (color_stone);
	const SColor color_minimap_thickstone   (color_thickstone);
	const SColor color_minimap_gold         (color_gold);
	const SColor color_minimap_bedrock      (color_bedrock);
	const SColor color_minimap_wood         (color_wood);
	const SColor color_minimap_castle       (color_castle);

	const SColor color_minimap_castle_back  (color_castle_backwall);
	const SColor color_minimap_wood_back    (color_wood_backwall);

	const SColor color_minimap_water        (color_water);
	const SColor color_minimap_fire         (color_fire);
	
	if (map.isTileGold(tile))  
	{ 
		col = show_gold ? color_minimap_gold : color_minimap_ground;
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
			bool custom_colors = cfg.read_bool("custom_colors", true);

			//write out values for serialisation
			rules.set_bool("legacy_minimap", map.legacyTileMinimap);
			rules.set_bool("show_gold", show_gold);
			rules.set_bool("custom_colors", custom_colors);
		}
		if (isClient())
		{
			// customizable colors for blocks
			ConfigFile cfg();
			if (cfg.loadFile("../Cache/MinimapColors.cfg"))
			{
				if (rules.get_bool("custom_colors") == true)
				{
					color_sky.set(parseInt(cfg.read_string("color_sky"), 16));
					color_sky.setAlpha(255);

					color_dirt.set(parseInt(cfg.read_string("color_dirt"), 16));
					color_dirt.setAlpha(255);

					color_dirt_backwall.set(parseInt(cfg.read_string("color_dirt_backwall"), 16));
					color_dirt_backwall.setAlpha(255);

					color_stone.set(parseInt(cfg.read_string("color_stone"), 16));
					color_stone.setAlpha(255);

					color_thickstone.set(parseInt(cfg.read_string("color_thickstone"), 16));
					color_thickstone.setAlpha(255);

					color_gold.set(parseInt(cfg.read_string("color_gold"), 16));
					color_gold.setAlpha(255);

					color_bedrock.set(parseInt(cfg.read_string("color_bedrock"), 16));
					color_bedrock.setAlpha(255);

					color_wood.set(parseInt(cfg.read_string("color_wood"), 16));
					color_wood.setAlpha(255);

					color_wood_backwall.set(parseInt(cfg.read_string("color_wood_backwall"), 16));
					color_wood_backwall.setAlpha(255);

					color_castle.set(parseInt(cfg.read_string("color_castle"), 16));
					color_castle.setAlpha(255);

					color_castle_backwall.set(parseInt(cfg.read_string("color_castle_backwall"), 16));
					color_castle_backwall.setAlpha(255);

					color_water.set(parseInt(cfg.read_string("color_water"), 16));
					color_water.setAlpha(255);

					color_fire.set(parseInt(cfg.read_string("color_fire"), 16));
					color_fire.setAlpha(255);
				}
			}
			else
			{
				// grab the one with defaults from base
				if (!cfg.loadFile("MinimapColors.cfg"))
				{
					warn("missing default map colors");
					cfg.add_string("color_sky", "A5BDC8");
					cfg.add_string("color_dirt", "844715");
					cfg.add_string("color_dirt_backwall", "3B1406");
					cfg.add_string("color_stone", "8B6849");
					cfg.add_string("color_thickstone", "42484B");
					cfg.add_string("color_gold", "FEA53D");
					cfg.add_string("color_bedrock", "D342D");
					cfg.add_string("color_wood", "C48715");
					cfg.add_string("color_wood_backwall", "552A11");
					cfg.add_string("color_castle", "637160");
					cfg.add_string("color_castle_backwall", "313412");
				 	cfg.add_string("color_water", "2cafde");
					cfg.add_string("color_fire", "d5543f");
					cfg.saveFile("MinimapColors.cfg");
				}

				cfg.saveFile("MinimapColors.cfg");
			}

			//write defaults for now
			map.legacyTileMinimap = false;
			rules.set_bool("show_gold", true);
		}
	}
}