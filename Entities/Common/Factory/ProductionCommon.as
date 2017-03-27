#include "ShopCommon.as";

const string PRODUCTION_ARRAY = "prod array";
const string PRODUCTION_QUEUE = "prod queue";
const string PRODUCTION_TRACKING_ARRAY = "production tracking";

ShopItem@ addOnDemandItem( CBlob@ this, const string &in  name, const string &in  iconName, const string &in  blobName, const string &in description )
{
	return addProductionItem( this, name, iconName, blobName, description, 1, false, 1 );	  // item.ticksToMake = 1 = make only on demand/on respawn
}

ShopItem@ addProductionItem( CBlob@ this, const string &in  name, const string &in  iconName, const string &in  blobName,
	const string &in  description, u16 timeToMakeSecs, bool spawnInCrate, const u16 quantityLimit, CBitStream@ requirements = null )
{
	return addProductionItem( this, PRODUCTION_ARRAY, name, iconName, blobName, description, timeToMakeSecs, spawnInCrate, quantityLimit, requirements );	
}		

ShopItem@ addProductionItem( CBlob@ this, const string &in shopArray, const string &in  name, const string &in  iconName,
	const string &in  blobName, const string &in  description, u16 timeToMakeSecs, bool spawnInCrate, const u16 quantityLimit, CBitStream@ requirements )
{
	ShopItem@ item = addShopItem( this, shopArray, name, iconName, blobName, description, false, spawnInCrate );
	if (item !is null)
	{	
		item.timeCreated = getGameTime();
		item.ticksToMake = timeToMakeSecs > 1 ? timeToMakeSecs * getTicksASecond() : 1;
		item.producing = true;
		item.inProductionNow = item.hasRequirements = item.inStock = false;
		if (requirements !is null) {
			item.requirements = requirements;
		}
		item.quantityLimit = quantityLimit;
	}
	return item;
}

bool canProduce( CBlob@ this, const string &in name )
{
	if (this.hasTag("production paused"))
		return false;

	ShopItem[]@ items;
	if (this.get( PRODUCTION_ARRAY, @items ))
	{
		for (uint i = 0 ; i < items.length; i++)
		{
			ShopItem @item = items[i];
			if (item.blobName == name)
				return true;
		}
	}
	return false;
}

bool isProducing(CBlob@ this)
{
	ShopItem[]@ items;
	if (this.get( PRODUCTION_ARRAY, @items ))
	{
		for (uint i = 0 ; i < items.length; i++)
		{
			ShopItem @item = items[i];
			if (item.inProductionNow)
				return true;
		}
	}

	return false;
}
