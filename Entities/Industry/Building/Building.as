// Genreic building

#include "Requirements.as"
#include "ShopCommon.as";
#include "Descriptions.as";
#include "WARCosts.as";
#include "CheckSpam.as";

//are builders the only ones that can finish construction?
const bool builder_only = false;

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_wood_back);
	//this.getSprite().getConsts().accurateLighting = true;

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(4, 4));
	this.set_string("shop description", "Construct");
	this.set_u8("shop icon", 12);
	this.Tag(SHOP_AUTOCLOSE);

	{
		ShopItem@ s = addShopItem(this, "Builder Shop", "$buildershop$", "buildershop", descriptions[54]);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_FACTORY);
	}
	{
		ShopItem@ s = addShopItem(this, "Quarters", "$quarters$", "quarters", descriptions[59]);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_FACTORY);
	}
	{
		ShopItem@ s = addShopItem(this, "Knight Shop", "$knightshop$", "knightshop", descriptions[55]);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_FACTORY);
	}
	{
		ShopItem@ s = addShopItem(this, "Archer Shop", "$archershop$", "archershop", descriptions[56]);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_FACTORY);
	}
	{
		ShopItem@ s = addShopItem(this, "Boat Shop", "$boatshop$", "boatshop", descriptions[58]);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);
	}
	{
		ShopItem@ s = addShopItem(this, "Vehicle Shop", "$vehicleshop$", "vehicleshop", descriptions[57]);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);
	}
	{
		ShopItem@ s = addShopItem(this, "Storage Cache", "$storage$", "storage", descriptions[60]);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 50);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
	}
	{
		ShopItem@ s = addShopItem(this, "Transport Tunnel", "$tunnel$", "tunnel", descriptions[34]);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.isOverlapping(caller))
		this.set_bool("shop available", !builder_only || caller.getName() == "builder");
	else
		this.set_bool("shop available", false);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();
	if (cmd == this.getCommandID("shop made item"))
	{
		this.Tag("shop disabled"); //no double-builds

		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		CBlob@ item = getBlobByNetworkID(params.read_netid());
		if (item !is null && caller !is null)
		{
			this.getSprite().PlaySound("/Construct.ogg");
			this.getSprite().getVars().gibbed = true;
			this.server_Die();

			// open factory upgrade menu immediately
			if (item.getName() == "factory")
			{
				CBitStream factoryParams;
				factoryParams.write_netid(caller.getNetworkID());
				item.SendCommand(item.getCommandID("upgrade factory menu"), factoryParams);
			}
		}
	}
}
