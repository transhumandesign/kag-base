CBlob@ server_MakeFood(Vec2f atpos, const string &in name, const u8 spriteIndex)
{
	if (!getNet().isServer()) { return null; }

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

CBlob@ cookFood(CBlob@ this)
{
	string cookedName;
	u8 spriteIndex;

	if (this.getName() == "fishy")
	{
		cookedName = "Cooked Fish";
		spriteIndex = 1;
	}
	else if (this.getName() == "steak")
	{
		cookedName = "Cooked Steak";
		spriteIndex = 0;
	}
	else if (this.getName() == "grain")
	{
		cookedName = "Bread";
		spriteIndex = 4;
	}
	else if (this.getName() == "egg")
	{
		cookedName = "Cake";
		spriteIndex = 5;
	}
	else
	{
		return null;
	}

	CBlob@ food = server_MakeFood(this.getPosition(), cookedName, spriteIndex);
	if (food !is null)
	{
		this.server_Die();
		food.getSprite().PlaySound("SparkleShort.ogg");
		return food;
	}
	return null;
}
