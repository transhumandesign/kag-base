// war/ctf png loader

#include "BasePNGLoader.as";
#include "WAR_Technology.as";
#include "MinimapHook.as";

// Custom map colors for WAR
namespace war_colors
{
	enum color
	{
		hall             = 0xFFD3F9C1, // ARGB(255, 211, 249, 193)
		tradingpost_1    = 0xFF8888FF,
		tradingpost_2    = 0xFFFF8888,
		blue_team_scroll = 0xFF000088,
		red_team_scroll  = 0xFF880000,
		crappy_scroll    = 0xFF563D56,
		medium_scroll    = 0xFF9A419B,
		super_scroll     = 0xFFCF31D1
	};
}

enum Offset
{
	blue_team_scroll = offsets_count,
	red_team_scroll,
	crap_scroll,
	medium_scroll,
	super_scroll,
	war_offsets_count
};


//the loader

class WarPNGLoader : PNGLoader
{
	WarPNGLoader()
	{
		super();

		SetupScrolls(getRules());

		//add missing offset arrays
		int count = war_offsets_count - offsets_count;
		while (count -- > 0)
		{
			offsets.push_back(array<int>(0));
		}
	}

	//override this to extend functionality per-pixel.
	void handlePixel(const SColor &in pixel, int offset) override
	{
		PNGLoader::handlePixel(pixel, offset);

		switch (pixel.color)
		{
		case war_colors::tradingpost_1:
		case war_colors::tradingpost_2:
			autotile(offset);
			spawnBlob(map, "tradingpost", offset, -1);
		break;
		//random scroll per-team
		case war_colors::blue_team_scroll: autotile(offset); offsets[blue_team_scroll].push_back(offset); break;
		case war_colors::red_team_scroll:  autotile(offset); offsets[ red_team_scroll].push_back(offset); break;
		//generic random scrolls
		case war_colors::crappy_scroll:    autotile(offset); offsets[     crap_scroll].push_back(offset); break;
		case war_colors::medium_scroll:    autotile(offset); offsets[   medium_scroll].push_back(offset); break;
		case war_colors::super_scroll:     autotile(offset); offsets[    super_scroll].push_back(offset); break;
		//halls
		case war_colors::hall:             autotile(offset); spawnBlob(map, "hall", offset); break;
		case map_colors::blue_main_spawn:  autotile(offset); spawnHall(map, offset, 0); break;
		case map_colors::red_main_spawn:   autotile(offset); spawnHall(map, offset, 1); break;
		};
	}

	//override this to add post-load offset types.
	void handleOffset(int type, int offset, int position, int count)
	{
		PNGLoader::handleOffset(type, offset, position, count);

		const Vec2f pos = getSpawnPosition(map, offset);
		if (type >= blue_team_scroll && type <= red_team_scroll)
		{
			if ((((getGameTime() + type) * 997) % count == position))
			{
				ScrollSet@ medium = getScrollSet("medium scrolls");
				if (medium !is null)
				{
					int index = XORRandom(medium.names.length);
					string defname = medium.names[index];
					ScrollDef@ def;
					medium.scrolls.get(defname, @def);
					if (def !is null)
					{
						server_MakePredefinedScroll(pos, defname);
					}
					else
						warn("Medium scroll not found " + defname);
				}
				else
					warn("Medium scrolls not found");
			}
		}
		else if (type >= crap_scroll && type <= super_scroll)
		{
			if (XORRandom(512) > 128)
			{
				ScrollSet@ all = getScrollSet("all scrolls");
				if (all !is null)
				{
					string defname = "";
					string setname;
					switch (type)
					{
						case crap_scroll:
							setname = "medium scrolls";
							break;
						case medium_scroll:
							setname = "medium scrolls";
							break;
						case super_scroll:
							setname = "super scrolls";
							break;
						default:
							setname = "all scrolls";
							break;
					}

					ScrollSet@ set = getScrollSet(setname);
					if (set !is null)
					{
						defname = set.names[XORRandom(set.names.length)];
						ScrollDef@ def;
						all.scrolls.get(defname, @def);
						if (def !is null)
						{
							if (def.items.length > 0 || def.scripts.length == 0)
							{
								server_MakePredefinedScroll(pos, defname);
							}
							else
								server_MakeScriptScroll(pos, def.name, def.scripts);
						}
						else
							warn("Scroll not found " + defname + " from " + setname);
					}
					else
						warn("Scroll set not found " + setname);
				}
				else
					warn("All scrolls not found");
			}
		}
	}
}

// --------------------------------------------------

bool LoadMap(CMap@ map, const string& in fileName)
{
	print("LOADING WAR PNG MAP " + fileName);

	WarPNGLoader loader();

	MiniMap::Initialise();

	return loader.loadMap(map , fileName);
}
