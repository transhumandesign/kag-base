// PNG loader base class - extend this to add your own PNG loading functionality!

#include "BasePNGLoader.as";
#include "LoaderUtilities.as";
#include "WAR_Technology.as";

const SColor color_hall(255, 211, 249, 193);

const SColor color_tradingpost_1(0xff8888ff);
const SColor color_tradingpost_2(0xffff8888);

const SColor color_blue_team_scroll(0xff000088);
const SColor color_red_team_scroll(0xff880000);

const SColor color_crappy_scroll(0xff563d56);
const SColor color_medium_scroll(0xff9a419b);
const SColor color_super_scroll(0xffcf31d1);

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
	void handlePixel(SColor pixel, int offset)
	{
		PNGLoader::handlePixel(pixel, offset);

		if (pixel == color_hall)
		{
			spawnBlob(map, "hall", offset, -1);
			offsets[autotile_offset].push_back(offset);
		}
		// TRADING POST
		else if (pixel == color_tradingpost_1)
		{
			spawnBlob(map, "tradingpost", offset, -1);
			offsets[autotile_offset].push_back(offset);
		}
		else if (pixel == color_tradingpost_2)
		{
			spawnBlob(map, "tradingpost", offset, -1);
			offsets[autotile_offset].push_back(offset);
		}
		//random scroll per-team
		else if (pixel == color_blue_team_scroll)
		{
			offsets[blue_team_scroll].push_back(offset);
			offsets[autotile_offset].push_back(offset);
		}
		else if (pixel == color_red_team_scroll)
		{
			offsets[red_team_scroll].push_back(offset);
			offsets[autotile_offset].push_back(offset);
		}
		//generic random scrolls
		else if (pixel == color_crappy_scroll)
		{
			offsets[crap_scroll].push_back(offset);
			offsets[autotile_offset].push_back(offset);
		}
		else if (pixel == color_medium_scroll)
		{
			offsets[medium_scroll].push_back(offset);
			offsets[autotile_offset].push_back(offset);
		}
		else if (pixel == color_super_scroll)
		{
			offsets[super_scroll].push_back(offset);
			offsets[autotile_offset].push_back(offset);
		}
		else if (pixel == color_blue_main_spawn)
		{
			CBlob@ hall = spawnBlob(map, "hall", offset, 0);
			if (hall !is null) // add research to first hall
			{
				hall.AddScript("Researching.as");
				hall.Tag("script added");
			}
			offsets[autotile_offset].push_back(offset);
		}
		else if (pixel == color_red_main_spawn)
		{
			CBlob@ hall = spawnBlob(map, "hall", offset, 1);
			if (hall !is null) // add research to first hall
			{
				hall.AddScript("Researching.as");
				hall.Tag("script added");
			}
			offsets[autotile_offset].push_back(offset);
		}

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

	return loader.loadMap(map , fileName);
}
