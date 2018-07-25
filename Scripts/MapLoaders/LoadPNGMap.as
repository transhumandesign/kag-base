// loads a classic KAG .PNG map
// fileName is "" on client!

#include "BasePNGLoader.as";
#include "MinimapHook.as";

bool LoadMap(CMap@ map, const string& in fileName)
{
	print("LOADING PNG MAP " + fileName);

	PNGLoader loader();

	MiniMap::Initialise();

	return loader.loadMap(map, fileName);
}