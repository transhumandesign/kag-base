// tech handling

#include "ShopCommon.as";

const string TECH_ARRAY = "tech array";

// quantityLimit = 0 = infinite

ShopItem@ addTechItem(CBlob@ this, const string &in niceName, const string &in blobName, const string &in iconName, const string &in description, u16 timeToMakeSecs, bool spawnInCrate, const u8 quantityLimit, CBitStream@ requirements)
{
	ShopItem@ item = addShopItem(this, TECH_ARRAY, niceName, iconName, blobName, description, false, spawnInCrate);
	if (item !is null)
	{
		item.ticksToMake = timeToMakeSecs > 1 ? timeToMakeSecs * getTicksASecond() : 1;
		item.quantityLimit = quantityLimit;
		item.requirements = requirements;
	}
	return item;
}

// techs are then copied in factory to production array - be sure to copy all vars