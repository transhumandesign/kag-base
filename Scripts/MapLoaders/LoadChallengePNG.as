// loads a classic KAG .PNG map

// PNG loader base class - extend this to add your own PNG loading functionality!

#include "BasePNGLoader.as";
#include "MinimapHook.as";

// Custom map colors for challenges
namespace challenge_colors
{
	enum color
	{
		hall          = 0xFFD3F9C1, // ARGB(255, 211, 249, 193)
		tradingpost_1 = 0xFF8888FF,
		tradingpost_2 = 0xFFFF8888,
		checkpoint    = 0xFFF7E5FD
	};
}

class ChallengePNGLoader : PNGLoader
{
	ChallengePNGLoader()
	{
		super();
	}

	//override this to extend functionality per-pixel.
	void handlePixel(const SColor &in pixel, int offset) override
	{
		PNGLoader::handlePixel(pixel, offset);

		switch (pixel.color)
		{
		case challenge_colors::tradingpost_1:
		case challenge_colors::tradingpost_2:
			autotile(offset);
			spawnBlob(map, "tradingpost", offset, -1);
		break;
		case map_colors::blue_main_spawn: offsets[autotile_offset].push_back(offset); break;
		case map_colors::red_main_spawn: autotile(offset); spawnHall(map, offset, 1); break;
		case challenge_colors::hall:     autotile(offset); spawnBlob(map, "hall", offset, -1); break;
		case challenge_colors::checkpoint: AddMarker(map, offset, "checkpoint"); break;
		};
	}
};

bool LoadMap(CMap@ map, const string& in fileName)
{
	print("LOADING CHALLENGE PNG MAP " + fileName);
	MiniMap::Initialise();
	return ChallengePNGLoader().loadMap(map, fileName);
}
