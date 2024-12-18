// Genreic building

#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"
#include "TeamIconToken.as"

//are builders the only ones that can finish construction?
const bool builder_only = false;

void onInit(CBlob@ this)
{
	//AddIconToken("$stonequarry$", "../Mods/Entities/Industry/CTFShops/Quarry/Quarry.png", Vec2f(40, 24), 4);
	this.set_TileType("background tile", CMap::tile_wood_back);
	//this.getSprite().getConsts().accurateLighting = true;

	ShopMadeItem@ onMadeItem = @onShopMadeItem;
	this.set("onShopMadeItem handle", @onMadeItem);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("has window");

	//INIT COSTS
	InitCosts();

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(4, 4));
	this.set_string("shop description", "Construct");
	this.set_u8("shop icon", 12);
	this.Tag(SHOP_AUTOCLOSE);

	int team_num = this.getTeamNum();

	{
		ShopItem@ s = addShopItem(this, "Builder Shop", getTeamIcon("buildershop", "BuilderShop.png", team_num, Vec2f(40, 24)), "buildershop", Descriptions::buildershop);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::buildershop_wood);
	}
	{
		ShopItem@ s = addShopItem(this, "Quarters", getTeamIcon("quarters", "Quarters.png", team_num, Vec2f(40, 24), 2), "quarters", Descriptions::quarters);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::quarters_wood);
	}
	{
		ShopItem@ s = addShopItem(this, "Knight Shop", getTeamIcon("knightshop", "KnightShop.png", team_num, Vec2f(40, 24)), "knightshop", Descriptions::knightshop);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::knightshop_wood);
	}
	{
		ShopItem@ s = addShopItem(this, "Archer Shop", getTeamIcon("archershop", "ArcherShop.png", team_num, Vec2f(40, 24)), "archershop", Descriptions::archershop);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::archershop_wood);
	}
	{
		ShopItem@ s = addShopItem(this, "Boat Shop", getTeamIcon("boatshop", "BoatShop.png", team_num, Vec2f(40, 24)), "boatshop", Descriptions::boatshop);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::boatshop_wood);
	}
	{
		ShopItem@ s = addShopItem(this, "Vehicle Shop", getTeamIcon("vehicleshop", "VehicleShop.png", team_num, Vec2f(40, 24)), "vehicleshop", Descriptions::vehicleshop);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::vehicleshop_wood);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", CTFCosts::vehicleshop_gold);
	}
	{
		ShopItem@ s = addShopItem(this, "Storage Cache", getTeamIcon("storage", "Storage.png", team_num, Vec2f(40, 24)), "storage", Descriptions::storagecache);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", CTFCosts::storage_stone);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::storage_wood);
	}
	{
		ShopItem@ s = addShopItem(this, "Transport Tunnel", getTeamIcon("tunnel", "Tunnel.png", team_num, Vec2f(40, 24)), "tunnel", Descriptions::tunnel);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", CTFCosts::tunnel_stone);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", CTFCosts::tunnel_wood);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", CTFCosts::tunnel_gold);
	}
	/*{
		ShopItem@ s = addShopItem(this, "Stone Quarry", "$stonequarry$", "quarry", Descriptions::quarry);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", CTFCosts::quarry_stone);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", CTFCosts::quarry_gold);
		AddRequirement(s.requirements, "no more", "quarry", "Stone Quarry", CTFCosts::quarry_count);
	}*/
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (this.isOverlapping(caller))
		this.set_bool("shop available", !builder_only || caller.getName() == "builder");
	else
		this.set_bool("shop available", false);
}

void onShopMadeItem(CBitStream@ params)
{
	if (!isServer()) return;

	u16 this_id, caller_id, item_id;
	string name;

	if (!params.saferead_u16(this_id) || !params.saferead_u16(caller_id) || !params.saferead_u16(item_id) || !params.saferead_string(name))
	{
		return;
	}

	CBlob@ this = getBlobByNetworkID(this_id);
	if (this is null) return;

	CBlob@ caller = getBlobByNetworkID(caller_id);
	if (caller is null) return;

	CBlob@ item = getBlobByNetworkID(item_id);
	if (item is null) return;

	this.Tag("shop disabled"); //no double-builds
	this.Sync("shop disabled", true);

	this.server_Die();

	// open factory upgrade menu immediately
	if (item.getName() == "factory")
	{
		CBitStream factoryParams;
		factoryParams.write_netid(caller.getNetworkID());
		item.SendCommand(item.getCommandID("upgrade factory menu"), factoryParams); // NOT SANITIZED; TTH
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item client") && isClient())
	{
		u16 this_id, caller_id, item_id;
		string name;

		if (!params.saferead_u16(this_id) || !params.saferead_u16(caller_id) || !params.saferead_u16(item_id) || !params.saferead_string(name))
		{
			return;
		}

		CBlob@ caller = getBlobByNetworkID(caller_id);
		CBlob@ item = getBlobByNetworkID(item_id);

		if (item !is null && caller !is null)
		{
			this.getSprite().PlaySound("/Construct.ogg");
			this.getSprite().getVars().gibbed = true;
			caller.ClearMenus();
		}
	}
}
