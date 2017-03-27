// loads a classic KAG .PNG map

// PNG loader base class - extend this to add your own PNG loading functionality!

#include "BasePNGLoader.as";

const SColor color_hall(255, 211, 249, 193);
const SColor color_tradingpost_1(0xff8888ff);
const SColor color_tradingpost_2(0xffff8888);
const SColor color_checkpoint(0xffF7E5FD);

//the loader

class ChallengePNGLoader : PNGLoader
{

	ChallengePNGLoader()
	{
		super();
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
		else if (pixel == color_blue_main_spawn)
		{
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
		else if (pixel == color_checkpoint)
		{
			AddMarker(map, offset, "checkpoint");
		}

	}

};

// --------------------------------------------------

bool LoadMap(CMap@ map, const string& in fileName)
{
	print("LOADING CHALLENGE PNG MAP " + fileName);

	ChallengePNGLoader loader();

	return loader.loadMap(map , fileName);
}
