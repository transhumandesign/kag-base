// TDM PNG loader base class - extend this to add your own PNG loading functionality!

#include "BasePNGLoader.as";
#include "LoaderUtilities.as";

const SColor color_tradingpost_1(0xff8888ff);
const SColor color_tradingpost_2(0xffff8888);

//the loader

class TDMPNGLoader : PNGLoader
{

	TDMPNGLoader()
	{
		super();
	}

	//override this to extend functionality per-pixel.
	void handlePixel(SColor pixel, int offset)
	{
		PNGLoader::handlePixel(pixel, offset);

		// TRADING POST
		if (pixel == color_tradingpost_1)
		{
			spawnBlob(map, "tradingpost", offset, 0);
			offsets[autotile_offset].push_back(offset);
		}
		else if (pixel == color_tradingpost_2)
		{
			spawnBlob(map, "tradingpost", offset, 1);
			offsets[autotile_offset].push_back(offset);
		}
	}

	//override this to add post-load offset types.
	void handleOffset(int type, int offset, int position, int count)
	{
		PNGLoader::handleOffset(type, offset, position, count);
	}
};

// --------------------------------------------------

bool LoadMap(CMap@ map, const string& in fileName)
{
	print("LOADING TDM PNG MAP " + fileName);

	TDMPNGLoader loader();

	return loader.loadMap(map , fileName);
}
