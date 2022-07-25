// BoatShop.as

#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "TeamIconToken.as"

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_wood_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	//INIT COSTS
	InitCosts();

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(8, 2));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	int team_num = this.getTeamNum();

	// TODO: Better information + icons like the vehicle shop, also make boats not suck
	{
		string dinghy_icon = getTeamIcon("dinghy", "VehicleIcons.png", team_num, Vec2f(32, 32), 5);
		ShopItem@ s = addShopItem(this, "Dinghy", dinghy_icon, "dinghy", dinghy_icon + "\n\n\n" + Descriptions::dinghy);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::dinghy_wood);
	}
	{
		string longboat_icon = getTeamIcon("longboat", "VehicleIcons.png", team_num, Vec2f(32, 32), 4);
		ShopItem@ s = addShopItem(this, "Longboat", longboat_icon, "longboat", longboat_icon + "\n\n\n" + Descriptions::longboat, false, true);
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::longboat);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::longboat_wood);
		s.crate_icon = 1;
	}
	{
		string warboat_icon = getTeamIcon("warboat", "VehicleIcons.png", team_num, Vec2f(32, 32), 2);
		ShopItem@ s = addShopItem(this, "War Boat", warboat_icon, "warboat", warboat_icon + "\n\n\n" + Descriptions::warboat, false, true);
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::warboat);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", CTFCosts::warboat_gold);
		s.crate_icon = 2;
	}
	{
		string fishingrod_icon = getTeamIcon("fishingrod", "FishingRod.png", team_num, Vec2f(32, 32), 1);
		ShopItem@ s = addShopItem(this, "Fishing Rod", fishingrod_icon, "fishingrod", fishingrod_icon + "\n\n\n\n" + Descriptions::fishingrod, false, false);
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::fishingrod);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::fishingrod_wood);
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
