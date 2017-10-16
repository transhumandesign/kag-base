
/**
 *	Template for modders - add custom blocks by
 *		putting this file in your mod with custom
 *		logic for creating tiles in HandleCustomTile.
 *
 * 		Don't forget to check your colours don't overlap!
 *
 *		Note: don't modify this file directly, do it in a mod!
 */

//#include MaterialCommon.as;

namespace CMap
{
	enum CustomTiles
	{
		//pick tile indices from here - indices > 256 are advised.
		tile_whatever = 300
	};
};

//Map loading
void HandleCustomTile(CMap@ map, int offset, SColor pixel)
{
	//change this in your mod
}

//Harvesting
void MaterialFromCustomTile(CBlob@ this, uint16 &in type, float &in damage)
{
  if (type == CMap::tile_whatever)
  {
    //Material::createFor(this, 'mat_whatever', damage);
  }
}