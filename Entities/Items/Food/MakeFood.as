#include "ProductionCommon.as";

CBlob@ server_MakeFood(Vec2f atpos, const string &in name, const u8 spriteIndex)
{
	if (!isServer())  return null; 

	CBlob@ blob = server_CreateBlobNoInit("food");
	if (blob !is null)
	{
		blob.setPosition(atpos);
		blob.set_string("food name", name);
		blob.set_u8("food sprite", spriteIndex);
		blob.Init();
	}
	return blob;
}

ShopItem@ addFoodItem(CBlob@ this, const string &in foodName, const u8 spriteIndex,
                      const string &in  description, u16 timeToMakeSecs, const u16 quantityLimit, CBitStream@ requirements = null)
{
	const string newIcon = "$" + foodName + "$";
	AddIconToken(newIcon, "Entities/Items/Food/Food.png", Vec2f(16, 16), spriteIndex);
	ShopItem@ item = addProductionItem(this, foodName, newIcon, "food", description, timeToMakeSecs, false, quantityLimit, requirements);
	if (item !is null)
	{
		item.customData = spriteIndex;
	}
	return item;
}

CBlob@ CookInFireplace(CBlob@ ingredient) // used by Fireplace.as
{
	if (ingredient.hasTag("cookable in fireplace"))
	{
		return Cook(ingredient);
	}
	return null;
}

CBlob@ Cook(CBlob@ ingredient) // used by Chicken.as and Fishy.as
{
	if (ingredient.hasTag("cooked") || ingredient.hasTag("healed") || !ingredient.exists("cooked name"))
		return null;

	string cooked_name 	= ingredient.get_string("cooked name");
	u8 sprite_index	= ingredient.get_u8("cooked sprite index");

	CBlob@ food = server_MakeFood(ingredient.getPosition(), cooked_name, sprite_index);
	
	ingredient.getSprite().PlaySound("SparkleShort.ogg");
	
	if (food !is null)
	{
		ingredient.Tag("cooked");
		ingredient.Sync("cooked", true);
		ingredient.server_Die();
		food.setVelocity(ingredient.getVelocity());
		return food;
	}
	return null;
}
