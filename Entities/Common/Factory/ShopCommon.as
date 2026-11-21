funcdef void ShopMadeItem(CBitStream@);

shared class ShopItem
{
	string name;
	string iconName;
	string blobName;
	string techName;
	string description;
	CBitStream requirements;
	// creating
	bool spawnToInventory;
	bool spawnInCrate;
	bool spawnNothing;
	int crate_icon;
	// production
	u32 ticksToMake;
	u32 timeCreated;
	bool producing;
	bool inProductionNow;
	bool hasRequirements;
	bool inStock;
	u8 quantityLimit;
	CBitStream requirementsMissing;
	// food production
	u8 customData;
	//button hack stuff
	bool customButton;
	u8 buttonwidth;
	u8 buttonheight;

	void Setup(string _name, string _iconName, string _blobName, string _description, bool _spawnToInventory, bool _spawnInCrate)
	{
		name = _name;
		iconName = _iconName;
		blobName = _blobName;
		description = _description;
		spawnToInventory = _spawnToInventory;
		spawnInCrate = _spawnInCrate;
		crate_icon = 0;

		producing = false;
		timeCreated = 0;
		ticksToMake = 0;
		inProductionNow = hasRequirements = inStock = false;
		quantityLimit = 0;
		customData = 0;

		spawnNothing = false;

		customButton = false;
	}

	ShopItem()
	{
		Setup("", "", "", "", false, false);
	}

	ShopItem(CBitStream @bt)
	{
		if (!Unserialise(bt))
		{
			warn("Error unserializing ShopItem");
			name = "";
		}
	}

	void Serialise(CBitStream@ stream)
	{
		stream.write_string(name);
		stream.write_string(iconName);
		stream.write_string(blobName);
		stream.write_string(techName);
		stream.write_string(description);
		stream.write_u32(ticksToMake);
		stream.write_bool(spawnInCrate);
		stream.write_bool(spawnNothing);
		stream.write_u8(quantityLimit);
		stream.write_u32(timeCreated);
		stream.write_CBitStream(requirements);
		stream.write_bool(producing);
		stream.write_u8(customData);

		stream.write_bool(customButton);
		if (customButton)
		{
			stream.write_u8(buttonwidth);
			stream.write_u8(buttonheight);
		}
	}

	bool Unserialise(CBitStream@ stream)
	{
		if (!stream.saferead_string(name)) return false;
		if (!stream.saferead_string(iconName)) return false;
		if (!stream.saferead_string(blobName)) return false;
		if (!stream.saferead_string(techName)) return false;
		if (!stream.saferead_string(description)) return false;
		if (!stream.saferead_u32(ticksToMake)) return false;
		if (!stream.saferead_bool(spawnInCrate)) return false;
		if (!stream.saferead_bool(spawnNothing)) return false;
		if (!stream.saferead_u8(quantityLimit)) return false;
		if (!stream.saferead_u32(timeCreated)) return false;
		if (!stream.saferead_CBitStream(requirements)) return false;
		if (!stream.saferead_bool(producing)) return false;
		if (!stream.saferead_u8(customData)) return false;

		if (!stream.saferead_bool(customButton)) return false;
		if (customButton)
		{
			if (!stream.saferead_u8(buttonwidth)) return false;
			if (!stream.saferead_u8(buttonheight)) return false;
		}

		return true;
	}


};

const string SHOP_ARRAY = "shop array";
const string SHOP_AUTOCLOSE = "auto close menu";

//adding a item to a blobs list of items

ShopItem@ addShopItem(CBlob@ this, const string &in name, const string &in iconName, const string &in blobName, const string &in description)
{
	return addShopItem(this, SHOP_ARRAY, name, iconName, blobName, description, false, false);
}

ShopItem@ addShopItem(CBlob@ this, const string &in name, const string &in iconName, const string &in blobName, const string &in description, bool spawnToInventory)
{
	return addShopItem(this, SHOP_ARRAY, name, iconName, blobName, description, spawnToInventory, false);
}

ShopItem@ addShopItem(CBlob@ this, const string &in name, const string &in  iconName, const string &in  blobName, const string &in description, bool spawnToInventory, bool spawnInCrate)
{
	return addShopItem(this, SHOP_ARRAY, name, iconName, blobName, description, spawnToInventory, spawnInCrate);
}

ShopItem@ addShopItem(CBlob@ this, const string &in shopArray, const string &in name, const string &in iconName, const string &in blobName, const string &in description, bool spawnToInventory, bool spawnInCrate)
{
	if (!this.exists(shopArray))
	{
		ShopItem[] items;
		this.set(shopArray, items);
	}

	// check if we are not duplicating
	ShopItem[]@ shop_items;
	if (this.get(shopArray, @shop_items))
	{
		for (uint i = 0 ; i < shop_items.length; i++)
		{
			ShopItem @item = shop_items[i];
			if (item.blobName == blobName && item.name == name)
			{
				item.name = name;
				item.iconName = iconName;
				item.blobName = blobName;
				item.description = description;
				item.spawnToInventory = spawnToInventory;
				item.spawnInCrate = spawnInCrate;
				return item;
			}
		}
	}

	// create a new one
	ShopItem p;
	p.Setup(name, iconName, blobName, description, spawnToInventory, spawnInCrate);

	this.push(shopArray, p);
	ShopItem@ p_ref;
	this.getLast(shopArray, @p_ref);
	return p_ref;
}


void ShopSendCreateData(CBlob@ this, CBitStream@ stream, const string &in shopArray)
{
	ShopItem[]@ items;
	if (this.get(shopArray, @items))
	{
		stream.write_u8(items.length);
		for (uint i = 0 ; i < items.length; i++)
		{
			ShopItem @item = items[i];
			item.Serialise(stream);
		}
	}
	else
		stream.write_u8(0);
}

bool ShopReceiveCreateData(CBlob@ this, CBitStream@ stream, const string &in shopArray)
{
	u8 itemsCount;
	if (!stream.saferead_u8(itemsCount))
	{
		warn("failed to read itemsCount");
		return false;
	}

	// this is received before onInit but we still check for safety and try not to duplicate items

	this.clear(shopArray);

	for (uint i = 0 ; i < itemsCount; i++)
	{
		ShopItem@ item = addShopItem(this, shopArray, "", "", "", "", false, false);
		if (item !is null)
		{
			if (!item.Unserialise(stream))
			{
				warn("Could not receive shop item for " + this.getName());
				continue;
			}
		}
	}

	return true;
}
