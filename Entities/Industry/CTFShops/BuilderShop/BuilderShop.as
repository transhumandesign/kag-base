// BuilderShop.as

#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_wood_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	//INIT COSTS
	InitCosts();
	
	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(4, 3));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	// CLASS
	this.set_Vec2f("class offset", Vec2f(-6, 0));
	this.set_string("required class", "builder");

	{
		ShopItem@ s = addShopItem(this, "Lantern", "$lantern$", "lantern", descriptions[9], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::lantern_wood);
	}
	{
		ShopItem@ s = addShopItem(this, "Bucket", "$bucket$", "bucket", descriptions[36], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::bucket_wood);
	}
	{
		ShopItem@ s = addShopItem(this, "Sponge", "$sponge$", "sponge", descriptions[53], false);
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::sponge);
	}
	{
		ShopItem@ s = addShopItem(this, "Boulder", "$boulder$", "boulder", descriptions[17], false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", CTFCosts::boulder_stone);
	}
	{
		ShopItem@ s = addShopItem(this, "Trampoline", "$trampoline$", "trampoline", descriptions[30], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::trampoline_wood);
	}
	{
		ShopItem@ s = addShopItem(this, "Saw", "$saw$", "saw", descriptions[12], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::saw_wood);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", CTFCosts::saw_stone);
	}
	{
		ShopItem@ s = addShopItem(this, "Drill", "$drill$", "drill", descriptions[43], false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", CTFCosts::drill_stone);
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::drill);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if(caller.getConfig() == this.get_string("required class"))
	{
		this.set_Vec2f("shop offset", Vec2f_zero);
	}
	else
	{
		this.set_Vec2f("shop offset", Vec2f(6, 0));
	}
	this.set_bool("shop available", this.isOverlapping(caller));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/ChaChing.ogg");
	}
}
