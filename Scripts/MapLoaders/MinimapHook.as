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

	bool show_gold = getRules().get_bool("show_gold");

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
	Tile tile_l = map.getTile(MiniMap::clampInsideMap(pos * ts - Vec2f(ts, 0), map));
	Tile tile_r = map.getTile(MiniMap::clampInsideMap(pos * ts + Vec2f(ts, 0), map));
	Tile tile_u = map.getTile(MiniMap::clampInsideMap(pos * ts - Vec2f(0, ts), map));
	Tile tile_d = map.getTile(MiniMap::clampInsideMap(pos * ts + Vec2f(0, ts), map));

	///figure out the correct colour
	if (
		//always solid
		map.isTileGround( tile ) || map.isTileStone( tile ) ||
        map.isTileBedrock( tile ) || map.isTileThickStone( tile ) ||
        map.isTileCastle( tile ) || map.isTileWood( tile ) ||
        //only solid if we're not showing gold separately
        (!show_gold && map.isTileGold( tile ))
    ) {
		//Foreground
		col = color_minimap_solid;

		//Edge
		if( MiniMap::isForegroundOutlineTile(tile_u, map) || MiniMap::isForegroundOutlineTile(tile_d, map) ||
		    MiniMap::isForegroundOutlineTile(tile_l, map) || MiniMap::isForegroundOutlineTile(tile_r, map) )
		{
			col = color_minimap_solid_edge;
		}
		else if(
			show_gold && (
				MiniMap::isGoldOutlineTile(tile_u, map, false) || MiniMap::isGoldOutlineTile(tile_d, map, false) ||
			    MiniMap::isGoldOutlineTile(tile_l, map, false) || MiniMap::isGoldOutlineTile(tile_r, map, false)
			)
		) {
			col = color_minimap_gold_edge;
		}
	}
	else if(map.isTileBackground(ctile) && !map.isTileGrass(tile))
	{
		//Background
		col = color_minimap_back;

		//Edge
		if( MiniMap::isBackgroundOutlineTile(tile_u, map) || MiniMap::isBackgroundOutlineTile(tile_d, map) ||
		    MiniMap::isBackgroundOutlineTile(tile_l, map) || MiniMap::isBackgroundOutlineTile(tile_r, map) )
		{
			col = color_minimap_back_edge;
		}
	}
	else if(show_gold && map.isTileGold(tile))
	{
		//Gold
		col = color_minimap_gold;

		//Edge
		if( MiniMap::isGoldOutlineTile(tile_u, map, true) || MiniMap::isGoldOutlineTile(tile_d, map, true) ||
		    MiniMap::isGoldOutlineTile(tile_l, map, true) || MiniMap::isGoldOutlineTile(tile_r, map, true) )
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