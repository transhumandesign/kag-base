#include "TechsCommon.as"
#include "ScrollCommon.as"

// from def

CBlob@ server_MakePredefinedScroll(Vec2f atpos, const string &in name)
{
	if (!getNet().isServer()) { return null; }

	ScrollDef@ def = getScrollDef("all scrolls", name);
	if (def !is null)
	{
		CBlob@ blob = server_CreateBlobNoInit("scroll");
		if (blob !is null)
		{
			blob.setPosition(atpos);
			blob.set_string("scroll defname0", name);
			blob.set_string("scroll name", def.name);
			blob.set_u8("scroll icon", def.scrollFrame);

			for (uint i = 0; i < def.scripts.length; i++)
			{
				blob.AddScript(def.scripts[i]);
			}

			for (uint i = 0; i < def.items.length; i++)
			{
				ShopItem@ tech = def.items[i];
				addTechItem(blob, tech.name, tech.blobName, tech.iconName, "", tech.ticksToMake, tech.spawnInCrate, tech.quantityLimit, @tech.requirements);
			}
			blob.Tag("tech");

			blob.Init();

		}
		return blob;
	}

	warn("Scroll not found " + name);
	return null;
}

// script scroll

CBlob@ server_MakeScriptScroll(Vec2f atpos, const string &in name, string[] scripts, const u8 iconFrame = 0)
{
	if (!getNet().isServer()) { return null; }

	CBlob@ blob = server_CreateBlobNoInit("scroll");
	if (blob !is null)
	{
		blob.setPosition(atpos);
		blob.set_string("scroll name", name);
		blob.set_u8("scroll icon", iconFrame);
		blob.Init();

		for (uint i = 0; i < scripts.length; i++)
		{
			blob.AddScript(scripts[i]);
		}
	}
	return blob;
}

void addScrollItemsToArray(const string &in niceName, const string &in blobName, const u16 timeToMakeSecs, const bool spawnInCrate, const u8 quantityLimit, ShopItem[]@ items, CBitStream @reqs = null)
{
	ShopItem item;

	item.name = niceName;
	item.blobName = blobName;
	item.iconName = "$" + blobName + "$";
	item.ticksToMake = timeToMakeSecs; // ! we take the secs so we don't have to convert later
	item.spawnInCrate = spawnInCrate;
	item.quantityLimit = quantityLimit;
	if (reqs !is null)
		item.requirements = reqs;

	item.spawnToInventory = false;
	item.timeCreated = 0;

	items.push_back(item);
}

void addScrollTechToArray(const string &in niceName, const string &in techname, ShopItem[]@ items)
{
	ShopItem item;

	item.name = niceName;
	item.blobName = "";
	item.iconName = "$" + techname + "$";
	item.techName = techname;
	item.ticksToMake = 0;
	item.spawnInCrate = false;
	item.quantityLimit = 0;
	item.spawnToInventory = false;
	item.timeCreated = 0;

	items.push_back(item);
}
