// BoatShop.as

#include "Requirements.as"
#include "ShopCommon.as";
#include "Descriptions.as";
#include "WARCosts.as";
#include "CheckSpam.as";

const s32 cost_dinghy = 25;
const s32 cost_longboat = 50;
const s32 cost_warboat = 250;

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_wood_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(3, 1));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	// TODO: Better information + icons like the vehicle shop, also make boats not suck
	{
		ShopItem@ s = addShopItem(this, "Dinghy", "$dinghy$", "dinghy", "$dinghy$\n\n\n" + descriptions[10]);
		AddRequirement(s.requirements, "coin", "", "Coins", cost_dinghy);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
	}
	{
		ShopItem@ s = addShopItem(this, "Longboat", "$longboat$", "longboat", "$longboat$\n\n\n" + descriptions[33], false, true);
		AddRequirement(s.requirements, "coin", "", "Coins", cost_longboat);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200);
		s.crate_icon = 1;
	}
	{
		ShopItem@ s = addShopItem(this, "War Boat", "$warboat$", "warboat", "$warboat$\n\n\n" + descriptions[37], false, true);
		AddRequirement(s.requirements, "coin", "", "Coins", cost_warboat);
		s.crate_icon = 2;
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	this.set_bool("shop available", this.isOverlapping(caller));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/ChaChing.ogg");
	}
}