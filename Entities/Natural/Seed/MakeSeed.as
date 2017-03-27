
// Making seeds - pass a blob name and grow time and it will set up and return the seed
// only functions on server - make sure to check for null.

// modify seed.as to make custom seed appearances

#include "ProductionCommon.as"

CBlob@ server_MakeSeed(Vec2f atpos, string blobname, u16 growtime, u8 spriteIndex, u8 created_blob_radius)
{
	if (!getNet().isServer()) { return null; }

	CBlob@ seed = server_CreateBlobNoInit("seed");

	if (seed !is null)
	{
		seed.setPosition(atpos);
		seed.set_string("seed_grow_blobname", blobname);
		seed.set_u16("seed_grow_time", growtime);
		seed.set_u8("sprite index", spriteIndex);
		seed.set_u8("created_blob_radius", created_blob_radius);
		seed.Init();
	}

	return seed;
}

CBlob@ server_MakeSeed(Vec2f atpos, string blobname, u16 growtime, u8 spriteIndex)
{
	return server_MakeSeed(atpos, blobname, growtime, spriteIndex, 4);
}

CBlob@ server_MakeSeed(Vec2f atpos, string blobname, u16 growtime)
{
	return server_MakeSeed(atpos, blobname, growtime, 0);
}

CBlob@ server_MakeSeed(Vec2f atpos, string blobname)
{
	if (blobname == "tree_pine")
	{
		return server_MakeSeed(atpos, blobname, 600, 2, 4);
	}
	else if (blobname == "tree_bushy")
	{
		return server_MakeSeed(atpos, blobname, 400, 3, 4);
	}
	else if (blobname == "grain_plant")
	{
		return server_MakeSeed(atpos, blobname, 300, 1, 4);
	}
	else if (blobname == "flowers")
	{
		return server_MakeSeed(atpos, blobname, 200, 6, 4);
	}
	else if (blobname == "bush")
	{
		return server_MakeSeed(atpos, blobname, 300, 5, 4);
	}

	return server_MakeSeed(atpos, blobname, 100, 0, 4);
}


ShopItem@ addSeedItem(CBlob@ this, const string &in seedName,
                      const string &in  description, u16 timeToMakeSecs, const u16 quantityLimit, CBitStream@ requirements = null)
{
	const string newIcon = "$" + seedName + "$";
	ShopItem@ item = addProductionItem(this, seedName, newIcon, "seed", description, timeToMakeSecs, false, quantityLimit, requirements);
	return item;
}
