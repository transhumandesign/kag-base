// War Base logic

#include "ClassSelectMenu.as"
#include "StandardRespawnCommand.as"
#include "MakeSeed.as"
#include "Descriptions.as"
#include "ShopCommon.as"
#include "Requirements.as"
#include "AddTilesBySector.as"
#include "Costs.as"
#include "GenericButtonCommon.as"

const Vec2f upgradeButtonPos(-36.0f, 10.0f);
const Vec2f classButtonPos(-76, 10);

//void InitClasses( CBlob@ this )
//{
//    addPlayerClass( this, "Builder", "$builder_class_icon$", "builder", "Build ALL the towers." );
//    addPlayerClass( this, "Knight", "$knight_class_icon$", "knight", "Hack and Slash." );
//    addPlayerClass( this, "Archer", "$archer_class_icon$", "archer", "The Ranged Advantage." );
//}

void InitWorkshop(CBlob@ this)
{
	//init costs from cfg
	InitCosts();

	this.set_Vec2f("shop offset", Vec2f(-110, 10));
	this.set_Vec2f("shop menu size", Vec2f(4, 5));

	{
		ShopItem@ s = addShopItem(this, "Lantern", "$lantern$", "lantern", Descriptions::lantern, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", WARCosts::lantern_wood);
	}
	{
		ShopItem@ s = addShopItem(this, "Crate", "$crate$", "crate", Descriptions::crate, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", WARCosts::crate_wood);
	}
	{
		ShopItem@ s = addShopItem(this, "Bucket", "$bucket$", "bucket", Descriptions::bucket, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", WARCosts::bucket_wood);
	}
	{
		ShopItem@ s = addShopItem(this, "Transport Tunnel", "$tunnel$", "tunnel", Descriptions::tunnel, false, true);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", WARCosts::tunnel_stone);
	}
	{
		ShopItem@ s = addShopItem(this, "Factory", "$factory$", "factory", Descriptions::factory, false, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", WARCosts::factory_wood);
	}
	{
		ShopItem@ s = addShopItem(this, "Kitchen", "$kitchen$", "kitchen", Descriptions::kitchen, false, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", WARCosts::kitchen_wood);
	}
}

void onInit(CBlob@ this)
{
	this.CreateRespawnPoint("base", Vec2f(0.0f, 16.0f));
	//set up classes
	AddIconToken("$WAR_BASE$", "Rules/WAR/WarGUI.png", Vec2f(48, 32), 10 + 2);
	AddIconToken("$builder_class_icon$", "GUI/MenuItems.png", Vec2f(32, 32), 8);
	AddIconToken("$knight_class_icon$", "GUI/MenuItems.png", Vec2f(32, 32), 12);
	AddIconToken("$archer_class_icon$", "GUI/MenuItems.png", Vec2f(32, 32), 16);
	//AddIconToken( "$upgrade_base$", "GUI/TechnologyIcons.png", Vec2f(16,16), 8 );
	//AddIconToken( "$food$", "Grain.png", Vec2f(8,8), 0 );
	AddIconToken("$seed$", "Seed.png", Vec2f(8, 8), 0);
	AddIconToken("$change_class$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 12, 2);
	InitClasses(this);
	//setup shop
	InitWorkshop(this);
	//set up shape
	this.getShape().SetStatic(true);
	this.getShape().getConsts().mapCollisions = false;
	// move inventory to sack on change class
	this.Tag("change class store inventory");

	//initialise any missing properties
	if (!this.exists("upgrade_level"))
	{
		this.set_u8("upgrade_level", 0);
	}

	this.set_u8("old_upgrade_level", 100);
	this.set_u8("old_upgrade_level_sprite", 100);

	if (!this.exists("food"))
	{
		this.set_u16("food", 0);
	}

	this.set_u16("old_food", u16(-1));

	// these are overwritten in War Rules script
	// !!!
	if (!this.exists("upgrade_1_cost"))
	{
		this.set_u16("upgrade_1_cost", 300);
	}

	if (!this.exists("upgrade_2_cost"))
	{
		this.set_u16("upgrade_2_cost", 800);
	}

	if (!this.exists("food_to_spawn"))
	{
		this.set_s16("food_to_spawn", 1);
	}

	this.set_u16("wood", 0);
	this.set_u16("old wood", 0);

	this.set_s16("wood for upgrade", woodForUpgrade(this));   //set up the wood for upgrade property
	this.set_s16("upgrade amount", upgradeAmount(this, this.get_u8("upgrade_level")));
	this.set_u8("seed pine amount", 0);
	this.set_u8("seed bushy amount", 0);
	this.set_u8("seed grain amount", 0);
	this.set_u8("seed pine max", 3);
	this.set_u8("seed bushy max", 2);
	this.set_u8("seed grain max", 5);
	this.set_u8("alert_time", 0);

	//hp stuff
	u8 default_hp = u8(this.getInitialHealth());
	this.set_u8("max_hp", default_hp);

	//commands
	this.addCommandID("dump wood");
	this.addCommandID("seed menu");
	this.addCommandID("seed pine");
	this.addCommandID("seed bushy");
	this.addCommandID("seed grain");
	this.addCommandID("convert grain");
	this.addCommandID("class menu");
	this.addCommandID("workbench menu");
	this.addCommandID("open storage");
	this.addCommandID("upgraded");
	this.addCommandID("NO_OP"); //dummy
	this.addCommandID("liftoff");
	this.addCommandID("shipment");
	this.Untag("!sectors"); // so sectors are created in onTick
	this.getSprite().getConsts().accurateLighting = true;
	this.inventoryButtonPos.Set(-16.0f, 20.0f);
}

void onTick(CBlob@ this)
{
	this.getSprite().SetZ(-50.0f);   // push to background
	const int team = this.getTeamNum();
	this.SetFacingLeft(team != 0);   // the sprites are flipped in the sprite sheet
	const int gametime = getGameTime() + team; //!
	const int performance_opt = 14;

	if (getNet().isServer() && (gametime % performance_opt == 7))
	{
		u8 alert = this.get_u8("alert_time");
		int myteam = this.getTeamNum();
		Vec2f pos = this.getPosition();
		CBlob@[] blobs;
		getBlobs(@blobs);

		for (uint blob_step = 0; blob_step < blobs.length; ++blob_step)
		{
			CBlob@ blob = blobs[blob_step];
			int blob_team = blob.getTeamNum();

			if (blob_team != myteam && blob_team < 32 && blob_team >= 0)
			{
				f32 dist = (blob.getPosition() - pos).Length();

				if (dist < 128.0f)
				{
					alert = 30;
					break;
				}
			}
		}

		if (alert > 0)
		{
			alert--;
		}

		this.set_u8("alert_time", alert);

	}

	if ((gametime % performance_opt == 0))
	{
		if (getNet().isServer())
		{
			s16 wood_amount = this.get_u16("wood");

			s16 upgrade_1 = this.get_u16("upgrade_1_cost");
			s16 upgrade_2 = this.get_u16("upgrade_2_cost");

			u8 old_level = this.get_u8("upgrade_level");
			u8 upgrade_level = (wood_amount >= upgrade_1 + upgrade_2) ? 2 : (wood_amount >= upgrade_1 ? 1 : 0);

			if (old_level != upgrade_level)
			{
				CBitStream params;
				params.write_u8(upgrade_level);
				params.write_u8(old_level);
				this.SendCommand(this.getCommandID("upgraded"), params);
			}

			this.set_u8("old_upgrade_level", old_level);
			this.set_u8("upgrade_level", upgrade_level);
			this.Sync("upgrade_level", true);
			//accumulate seeds
			u8 seed_count;

			if (gametime % 128 * performance_opt == 0)
			{
				seed_count = this.get_u8("seed pine amount");

				if (seed_count < this.get_u8("seed pine max"))
				{
					this.set_u8("seed pine amount", seed_count + 1);
					this.Sync("seed pine amount", true);
				}
			}

			if (gametime % 128 * performance_opt == 0)
			{
				seed_count = this.get_u8("seed bushy amount");

				if (seed_count < this.get_u8("seed bushy max"))
				{
					this.set_u8("seed bushy amount", seed_count + 1);
					this.Sync("seed bushy amount", true);
				}
			}

			if (gametime % 86 * performance_opt == 0)
			{
				seed_count = this.get_u8("seed grain amount");

				if (seed_count < this.get_u8("seed grain max"))
				{
					this.set_u8("seed grain amount", seed_count + 1);
					this.Sync("seed grain amount", true);
				}
			}

			this.set_s16("wood for upgrade", woodForUpgrade(this));   //set up the wood for upgrade property
			this.set_s16("upgrade amount", upgradeAmount(this, upgrade_level));

		} // server

		this.set_bool("shop available", this.get_u8("upgrade_level") >= 2);

		// setup non-buildable sectors

		if (!this.hasTag("!sectors"))
		{
			this.Tag("!sectors");

			CMap@ map = this.getMap();
			const f32 tilesize = map.tilesize;
			Vec2f pos = this.getPosition();

			const f32 sign = this.isFacingLeft() ? -1.0f : 1.0f;

			Vec2f ul = Vec2f(pos.x - sign * 6 * tilesize, pos.y - 1 * tilesize);
			Vec2f lr = Vec2f(pos.x + sign * 5  * tilesize, pos.y + 3 * tilesize);
			if (sign < 0.0f)
			{
				f32 tmp = ul.x;
				ul.x = lr.x;
				lr.x = tmp;
			}
			map.server_AddSector(ul, lr, "no build", "", this.getNetworkID());
			AddTilesBySector(ul, lr, "no build", CMap::tile_castle_back);

			ul = Vec2f(pos.x - sign * 4 * tilesize, pos.y - 2 * tilesize);
			lr = Vec2f(pos.x - sign * 2  * tilesize, pos.y - 1 * tilesize);
			if (sign < 0.0f)
			{
				f32 tmp = ul.x;
				ul.x = lr.x;
				lr.x = tmp;
			}
			map.server_AddSector(ul, lr, "no build", "", this.getNetworkID());
			AddTilesBySector(ul, lr, "no build", CMap::tile_castle_back);

			ul = Vec2f(pos.x - sign * 2 * tilesize, pos.y - 3 * tilesize);
			lr = Vec2f(pos.x + sign * 2 * tilesize, pos.y - 1 * tilesize);
			if (sign < 0.0f)
			{
				f32 tmp = ul.x;
				ul.x = lr.x;
				lr.x = tmp;
			}
			map.server_AddSector(ul, lr, "no build", "", this.getNetworkID());   // tower
			AddTilesBySector(ul, lr, "no build", CMap::tile_castle_back);

			//barracks
			ul = Vec2f(pos.x - sign * 12 * tilesize, pos.y - 1 * tilesize);
			lr = Vec2f(pos.x - sign * 6  * tilesize, pos.y + 3 * tilesize);
			if (sign < 0.0f)
			{
				f32 tmp = ul.x;
				ul.x = lr.x;
				lr.x = tmp;
			}
			map.server_AddSector(ul, lr, "no build", "", this.getNetworkID());
			//AddTilesBySector( ul, lr, CMap::tile_castle_back );

			ul = Vec2f(pos.x - sign * 11 * tilesize, pos.y - 2 * tilesize);
			lr = Vec2f(pos.x - sign * 9  * tilesize, pos.y - 1 * tilesize);
			if (sign < 0.0f)
			{
				f32 tmp = ul.x;
				ul.x = lr.x;
				lr.x = tmp;
			}
			map.server_AddSector(ul, lr, "no build", "", this.getNetworkID());
			//AddTilesBySector( ul, lr, CMap::tile_castle_back );

			ul = Vec2f(pos.x - sign * 17 * tilesize, pos.y - 0 * tilesize);
			lr = Vec2f(pos.x - sign * 12  * tilesize, pos.y + 3 * tilesize);
			if (sign < 0.0f)
			{
				f32 tmp = ul.x;
				ul.x = lr.x;
				lr.x = tmp;
			}
			map.server_AddSector(ul, lr, "no build", "", this.getNetworkID());
			//AddTilesBySector( ul, lr, CMap::tile_castle_back );
		}
	}

	if (getNet().isServer())
	{
		//if (gametime % 299 == 0)
		//  PickUpIntoStorage( this, true );
		if (gametime % 400 == 0)
			PickUpIntoStorage(this);
	}

}


//helpers



s16 maxWood(CBlob@ this)
{
	s16 upgrade_1 = this.get_u16("upgrade_1_cost");
	s16 upgrade_2 = this.get_u16("upgrade_2_cost");
	return upgrade_1 + upgrade_2;
}

s16 upgradeAmount(CBlob@ this, int currentlevel)
{
	if (currentlevel == 0)
	{
		return this.get_u16("upgrade_1_cost");
	}
	else if (currentlevel == 1)
	{
		return this.get_u16("upgrade_2_cost");
	}
	else
	{
		return 0;
	}
}

s16 lastUgradeAmount(CBlob@ this, int currentlevel)
{
	s16 amount = 0;

	while (currentlevel > 0)
	{
		amount += upgradeAmount(this, --currentlevel);
	}

	return amount;
}

s16 woodForUpgrade(CBlob@ this)
{
	u8 upgrade_level = this.get_u8("upgrade_level");
	s16 wood_amount = this.get_u16("wood");
	s16 last = lastUgradeAmount(this, upgrade_level);
	return wood_amount - last;
}

s16 woodTilUpgrade(CBlob@ this)
{
	u8 upgrade_level = this.get_u8("upgrade_level");
	s16 wood_amount = this.get_u16("wood") - lastUgradeAmount(this, upgrade_level);
	return upgradeAmount(this, upgrade_level) - wood_amount;
}

bool isInRadius(CBlob@ this, CBlob @caller)	
{	
	return ((this.getPosition() - caller.getPosition()).Length() < this.getRadius() * 2.0f + caller.getRadius());	
}

////////////////////////////////////////////////////
//Interactions
////////////////////////////////////////////////////

//for swapping class
bool canChangeClass2(CBlob@ this, CBlob @caller)
{
	return (this.get_u8("upgrade_level") >= 1) && isInRadius(this, caller);
}

//for the workbench
bool canUseWorkbench(CBlob@ this, CBlob @caller)
{
	return (this.get_u8("upgrade_level") >= 2) && isInRadius(this, caller);
}


void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	CBitStream params;
	params.write_u16(caller.getNetworkID());

	if (this.get_u8("upgrade_level") >= 1)
	{
		if (canChangeClass2(this, caller))
		{
			f32 offsetx = classButtonPos.x + 10.0f;
			if ((this.getPosition() + Vec2f(this.isFacingLeft() ? -offsetx : offsetx, classButtonPos.y) - caller.getPosition()).Length() < 18.0f)
			{
				BuildRespawnMenuFor(this, caller);
			}
			else
			{
				caller.CreateGenericButton("$change_class$", classButtonPos, this, this.getCommandID("class menu"), getTranslatedString("Change class"), params);
			}
		}
	}

	caller.CreateGenericButton("$seed$", Vec2f(24, 10), this, this.getCommandID("seed menu"), "Seed nursery", params);

	if (this.get_u8("upgrade_level") < 2) // upgrade button
	{
		CButton@ button = caller.CreateGenericButton("$mat_wood$", upgradeButtonPos, this, this.getCommandID("dump wood"), "Use wood to upgrade", params);
		if (button !is null)
		{
			button.deleteAfterClick = false;
			button.SetEnabled(hasBlob(caller, "mat_wood"));
		}
	}

	//caller.CreateGenericButton( 12, Vec2f(40, -10), this, this.getCommandID("liftoff"), "Armageddon", params );
}

//commands

void giveSeedCMD(CBlob@ this, string propertyName, string blobName, int growtime, u8 spriteIndex, u8 radius, CBitStream@ params)
{
	u8 seed_count = this.get_u8(propertyName);

	if (seed_count > 0)
	{
		u16 callerID = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(callerID);
		CInventory@ inv = caller.getInventory();

		if (inv !is null)
		{
			CBlob@ seed = server_MakeSeed(caller.getPosition(), blobName, growtime, spriteIndex, radius);

			if (seed !is null)
			{
				this.set_u8(propertyName, seed_count - 1);
				this.Sync(propertyName, true);

				if (caller.getCarriedBlob() is null)
				{
					caller.server_Pickup(seed);
				}
				else
				{
					caller.server_PutInInventory(seed);
				}
			}
		}
	}
}

//this should be an include...
bool hasBlob(CBlob@ this, const string& in name)
{
	CBlob@ handsBlob = this.getCarriedBlob();

	if (handsBlob !is null && handsBlob.getName() == name)
	{
		return true;
	}

	return this.getInventory().getCount(name) > 0;
}

void PutCarriedInInventory(CBlob@ this, const string& in carriedName)
{
	CBlob@ handsBlob = this.getCarriedBlob();

	if (handsBlob !is null && handsBlob.getName() == carriedName)
	{
		this.server_PutInInventory(handsBlob);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();
	//printf("base cmd " + cmd );

	if (cmd == this.getCommandID("dump wood"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		CInventory@ inv = caller.getInventory();

		if (inv !is null)
		{
			if (isServer)
			{
				PutCarriedInInventory(caller, "mat_wood");   // put carried wood in inventory before dumping so its easier to do if you dont have it in inv
				int wood_count = Maths::Min(woodTilUpgrade(this), Maths::Min(100, inv.getCount("mat_wood")));

				if (wood_count > 0)
				{
					inv.server_RemoveItems("mat_wood", wood_count);
					this.set_u16("wood", this.get_u16("wood") + wood_count);
					this.Sync("wood", true);
				}
			}

			// disable button if used up wood or upgrade level full
			if (inv.getCount("mat_wood") == 0 || this.get_u8("upgrade_level") >= 2)
			{
				CButton@ button = getHUD().getButtonWithCommandID(cmd);

				if (button !is null)
				{
					button.SetEnabled(false);    // FIXME: this function is broken
				}
			}
		}
	}
	else if (cmd == this.getCommandID("seed menu"))
	{
		u16 callerID = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(callerID);

		if (caller !is null && caller.isMyPlayer())
		{
			MakeSeedMenu(this, caller);
		}
	}
	else if (cmd == this.getCommandID("class menu"))
	{
		u16 callerID = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(callerID);
		if (caller !is null && caller.isMyPlayer())
		{
			BuildRespawnMenuFor(this, caller);
		}
	}
	//else if (cmd == this.getCommandID("workbench menu"))
	//{
	//    u16 callerID = params.read_u16();
	//    CBlob@ caller = getBlobByNetworkID( callerID );
	//    if (caller !is null && caller.isMyPlayer())
	//    {
	//        BuildShopMenu(this, caller, "Build in workbench", Vec2f(200,-50), Vec2f(8,6) );
	//    }
	//}
	else if (isServer && cmd == this.getCommandID("seed pine"))
	{
		giveSeedCMD(this, "seed pine amount", "tree_pine", 600, 1, 16, params);
	}
	else if (isServer && cmd == this.getCommandID("seed bushy"))
	{
		giveSeedCMD(this, "seed bushy amount", "tree_bushy", 400, 2, 16, params);
	}
	else if (isServer && cmd == this.getCommandID("seed grain"))
	{
		giveSeedCMD(this, "seed grain amount", "grain_plant", 300, 0, 8, params);
	}
	else if (isServer && cmd == this.getCommandID("convert grain"))
	{
		const u16 callerID = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(callerID);
		ConvertGrainIntoSeed(this, caller);
	}
	else if (cmd == this.getCommandID("liftoff"))
	{
		this.AddScript("WAR_liftoff");
	}
	else if (isServer && cmd == this.getCommandID("upgraded"))
	{
		u8 upgrade_level = params.read_u8();
		u8 old_level = params.read_u8();

		if (old_level != upgrade_level) //not quite guaranteed, safest to check
		{
			//increase the amount of hps
			u8 health = u8(this.get_u8("max_hp") * 1.5);
			this.set_u8("max_hp", health);

			this.server_SetHealth(health);

			//if (upgrade_level == 2 && !this.hasTag("dropped scroll"))
			//{
			//  this.Tag("dropped scroll");
			//  server_MakePredefinedScroll( this.getPosition(), "military basics" );
			//}
		}
	}
	else if (cmd == this.getCommandID("shipment"))
	{
		CBlob@ localBlob = getLocalPlayerBlob();
		if (localBlob !is null && localBlob.getTeamNum() == this.getTeamNum())
		{
			client_AddToChat("Supplies will drop at your base.");
			Sound::Play("/ShipmentHorn");
		}
	}
	else
	{
		onRespawnCommand(this, cmd, params);
	}
}

void onDie(CBlob@ this)
{
	this.getSprite().Gib();

	Vec2f pos = this.getPosition();
	Vec2f ul(pos.x - 128, pos.y - 80);
	Vec2f lr(pos.x + 128, pos.y + 40);
	AddTilesBySector(ul, lr, "no build", CMap::tile_empty);

	this.getSprite().PlaySound("/BuildingExplosion");
	ShakeScreen(53.0f, 150, pos);
}

// SPRITE
//animation

void onInit(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	const string filename = CFileMatcher("/WAR_base.png").getFirst();
	const int blob_team = blob.getTeamNum();
	const int blob_skin = blob.getSkinNum();
	//upgrade sprites
	{
		Vec2f tunnel_offset(32, 12);

		CSpriteLayer@ tunnel = this.addSpriteLayer("tunnel", filename , 24, 24, blob_team, blob_skin);

		if (tunnel !is null)
		{
			Animation@ anim = tunnel.addAnimation("default", 0, false);
			anim.AddFrame(49);

			tunnel.SetOffset(tunnel_offset);
			tunnel.SetVisible(false);
		}

		CSpriteLayer@ upgrade_table = this.addSpriteLayer("upgrade_table", filename , 24, 24, blob_team, blob_skin);

		if (upgrade_table !is null)
		{
			Animation@ anim = upgrade_table.addAnimation("default", 0, false);
			anim.AddFrame(38);
			anim.AddFrame(39);
			anim.AddFrame(48);

			upgrade_table.SetVisible(false);

			upgrade_table.SetOffset(tunnel_offset);
		}
	}
	//tower sprites
	{
		CSpriteLayer@ tower_cap = this.addSpriteLayer("tower_cap", filename , 32, 32, blob_team, blob_skin);

		if (tower_cap !is null)
		{
			Animation@ anim = tower_cap.addAnimation("default", 0, false);
			anim.AddFrame(16);
			anim.AddFrame(24);
		}

		CSpriteLayer@ tower = this.addSpriteLayer("tower", filename , 32, 32, blob_team, blob_skin);

		if (tower !is null)
		{
			Animation@ anim = tower.addAnimation("default", 0, false);
			anim.AddFrame(17);
			anim.AddFrame(18);
			anim.AddFrame(25);
			anim.AddFrame(26);
			tower.SetVisible(false);
		}

		CSpriteLayer@ tower_flagpole = this.addSpriteLayer("tower_flagpole", "Entities/Special/CTF/CTF_Flag.png" , 16, 32, blob_team, blob_skin);

		if (tower_flagpole !is null)
		{
			Animation@ anim = tower_flagpole.addAnimation("default", 0, false);
			anim.AddFrame(3);
		}

		CSpriteLayer@ tower_flag = this.addSpriteLayer("tower_flag", "Entities/Special/CTF/CTF_Flag.png" , 32, 16, blob_team, blob_skin);

		if (tower_flag !is null)
		{
			Animation@ anim = tower_flag.addAnimation("default", 3, true);
			anim.AddFrame(0);
			anim.AddFrame(2);
			anim.AddFrame(4);
			anim.AddFrame(6);
		}
	}
	//food sprites
	{
		Vec2f food_offset = Vec2f(0, 0);
		CSpriteLayer@ food1 = this.addSpriteLayer("food1", filename , 32, 16, blob_team, blob_skin);

		if (food1 !is null)
		{
			Animation@ anim = food1.addAnimation("default", 0, false);
			anim.AddFrame(24);
			food1.SetVisible(false);
			food1.SetOffset(food_offset + Vec2f(7.0f, 6.0f));
		}

		CSpriteLayer@ food2 = this.addSpriteLayer("food2", filename , 32, 16, blob_team, blob_skin);

		if (food2 !is null)
		{
			food2.SetOffset(food_offset + Vec2f(5.0f, 14.0f));
			Animation@ anim = food2.addAnimation("default", 0, false);
			anim.AddFrame(25);
			food2.SetVisible(false);
		}

		CSpriteLayer@ food3 = this.addSpriteLayer("food3", filename , 16, 16, blob_team, blob_skin);

		if (food3 !is null)
		{
			Animation@ anim = food3.addAnimation("default", 0, false);
			anim.AddFrame(52);
			food3.SetVisible(false);
			food3.SetOffset(food_offset + Vec2f(0.0f, -7.0f));
		}
	}
	//barracks sprites
	{
		Vec2f barracks_offset = Vec2f(88, 0);
		CSpriteLayer@ barracks_unbuilt = this.addSpriteLayer("barracks_unbuilt", filename , 96, 16, blob_team, blob_skin);

		if (barracks_unbuilt !is null)
		{
			Animation@ anim = barracks_unbuilt.addAnimation("default", 0, false);
			anim.AddFrame(13);
			barracks_unbuilt.SetVisible(true);
			barracks_unbuilt.SetOffset(barracks_offset + Vec2f(0.0f, 16.0f));
			barracks_unbuilt.SetRelativeZ(-50.0);
		}

		CSpriteLayer@ barracks = this.addSpriteLayer("barracks", filename , 96, 48, blob_team, blob_skin);

		if (barracks !is null)
		{
			Animation@ anim = barracks.addAnimation("default", 0, false);
			anim.AddFrame(1);
			anim.AddFrame(3);
			barracks.SetVisible(false);
			barracks.SetOffset(barracks_offset + Vec2f(0.0f, 0.0f));
			barracks.SetRelativeZ(-50.0);
		}

		CSpriteLayer@ barracks_weapons = this.addSpriteLayer("barracks_weapons", filename, 32, 32, blob_team, blob_skin);

		if (barracks_weapons !is null)
		{
			Animation@ anim = barracks_weapons.addAnimation("default", 0, false);
			anim.AddFrame(6);
			barracks_weapons.SetVisible(false);
			barracks_weapons.SetOffset(barracks_offset + Vec2f(-3.0f, 9.0f));
			barracks_weapons.SetRelativeZ(-50.0);
		}

		CSpriteLayer@ barracks_bench = this.addSpriteLayer("barracks_bench", filename , 32, 32, blob_team, blob_skin);

		if (barracks_bench !is null)
		{
			Animation@ anim = barracks_bench.addAnimation("default", 0, false);
			anim.AddFrame(14);
			barracks_bench.SetVisible(false);
			barracks_bench.SetOffset(barracks_offset + Vec2f(24.0f, 8.0f));
			barracks_bench.SetRelativeZ(-50.0);
		}
	}
	blob.set_u8("old_upgrade_level", 100); //hack, makes client sync frames
	onTick(this);   //update to get offsets etc working
}

void onTick(CSprite@ this)
{
	int gametime = getGameTime();
	this.SetZ(-50.0f);   // push to background

	//tower anim

	if ((gametime) % 10 == 0)
	{
		CBlob@ blob = this.getBlob();
		u8 old_upgrade_level = blob.get_u8("old_upgrade_level_sprite");
		u8 upgrade_level = blob.get_u8("upgrade_level");

		if (upgrade_level != old_upgrade_level)
		{
			blob.set_u8("old_upgrade_level_sprite", upgrade_level);
			SetupLayers(this, upgrade_level, false);
		}
		else
		{
			f32 health = blob.getHealth();
			f32 oldhealth = blob.get_f32("warbase old health"); //prevent potential collisions
			f32 defaulthp = blob.getInitialHealth();

			if (health != oldhealth)
			{
				if (health < defaulthp * 0.6f)
				{
					SetupLayers(this, upgrade_level, true);
				}
				else
				{
					SetupLayers(this, upgrade_level, false);
				}

				blob.set_f32("warbase old health", health);
			}

			if (upgrade_level < 2)
			{
				SetupUpgradeTable(this);
			}
			else
			{
				SetupTunnelLayer(this);
			}
		}
	}

	//food anim

	if ((gametime + 3) % 10 == 0)
	{
		CBlob@ blob = this.getBlob();
		s16 old_food = blob.get_u16("old_food");
		s16 food = blob.get_u16("food");

		if (food != old_food)
		{
			blob.set_u16("old_food", food);
			CSpriteLayer@ food1 = this.getSpriteLayer("food1");

			if (food1 !is null)
			{
				if (food > 350)
				{
					food1.SetVisible(true);
				}
				else
				{
					food1.SetVisible(false);
				}
			}

			CSpriteLayer@ food2 = this.getSpriteLayer("food2");

			if (food2 !is null)
			{
				if (food > 0)
				{
					food2.SetVisible(true);
				}
				else
				{
					food2.SetVisible(false);
				}
			}

			CSpriteLayer@ food3 = this.getSpriteLayer("food3");

			if (food3 !is null)
			{
				if (food > 100)
				{
					food3.SetVisible(true);
				}
				else
				{
					food3.SetVisible(false);
				}
			}
		}
	}
}


void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	CBlob@ localBlob = getLocalPlayerBlob();
	Vec2f upgradePos(blob.isFacingLeft() ? -upgradeButtonPos.x : upgradeButtonPos.x, upgradeButtonPos.y);
	upgradePos += blob.getPosition();

	if (localBlob !is null && (
	            ((localBlob.getPosition() - upgradePos).Length() < localBlob.getRadius() + 64.0f) &&
	            (getHUD().hasButtons() && !getHUD().hasMenus())))
	{
		Vec2f pos2d = blob.getScreenPos();
		const uint level = blob.get_u8("upgrade_level");
		CCamera@ camera = getCamera();
		f32 zoom = camera.targetDistance;
		int top = pos2d.y + zoom * blob.getHeight() + 160.0f;
		const uint margin = 7;
		Vec2f dim;
		string label = getTranslatedString("Level {LEVEL}").replace("{LEVEL}", "" + 10000);
		GUI::SetFont("menu");
		GUI::GetTextDimensions(label , dim);
		dim.x += 2.0f * margin;
		dim.y += 2.0f * margin;
		dim.y *= 2.0f;
		f32 leftX = -dim.x;
		int current = 0, max = 0;

		// DRAW UPGRADE LEVELS

		if (level == 0)
		{
			current = blob.get_u16("wood");
			max = blob.get_u16("upgrade_1_cost");
		}
		else if (level == 1)
		{
			current = blob.get_u16("wood") - blob.get_u16("upgrade_1_cost");
			max = blob.get_u16("upgrade_2_cost");
		}

		if (level < 2)
		{
			for (uint i = 0; i < 3; i++)
			{
				label = getTranslatedString("Level {LEVEL}").replace("{LEVEL}", "" + (i + 1));
				Vec2f upperleft(pos2d.x - dim.x / 2 + leftX, top - 2 * dim.y);
				Vec2f lowerright(pos2d.x + dim.x / 2 + leftX, top - dim.y);
				bool isNextLevel = (i == level + 1);
				f32 progress = 0.0f;

				if (i == 0)
				{
					progress = 1.0f;
				}
				else if (isNextLevel)
				{
					progress = float(current) / float(max);
				}
				else if (i <= level)
				{
					progress = 1.0f;
				}

				GUI::DrawProgressBar(upperleft, lowerright, progress);
				int base_frame = 10 + i;
				GUI::DrawIcon("Rules/WAR/WarGUI.png", base_frame, Vec2f(48, 32), upperleft + Vec2f(0, 0), 1.0f, blob.getTeamNum());
				GUI::DrawText(label, Vec2f(upperleft.x + margin, upperleft.y + margin), level == i ? SColor(255, 255, 255, 255) : SColor(255, 120, 120, 120));

				if (isNextLevel)
				{
					GUI::DrawText("" + current + " / " + max, Vec2f(upperleft.x + margin, upperleft.y + dim.y / 2.0f + margin), color_white);
				}

				leftX += dim.x + 2.0f;
			}
		}

	}  // E
}


void SetupLayers(CSprite@ this, u8 upgrade_level, bool damaged)
{
	Vec2f cap_offset = Vec2f(0, -24);
	CSpriteLayer@ tower_cap = this.getSpriteLayer("tower_cap");

	if (tower_cap !is null)
	{
		tower_cap.SetOffset(cap_offset + Vec2f(0.0f, (-16.0f * upgrade_level)));
		tower_cap.SetRelativeZ(-10.0);
		tower_cap.animation.frame = damaged ? 1 : 0;
	}

	Vec2f flag_offset = Vec2f(-4, -16 + (-8 * s32(upgrade_level)));
	CSpriteLayer@ tower_flagpole = this.getSpriteLayer("tower_flagpole");

	if (tower_flagpole !is null)
	{
		tower_flagpole.SetOffset(cap_offset + flag_offset + Vec2f(16.0f, (-16.0f * upgrade_level)));
		tower_flagpole.SetRelativeZ(-10.0);
	}

	CSpriteLayer@ tower_flag = this.getSpriteLayer("tower_flag");

	if (tower_flag !is null)
	{
		tower_flag.SetOffset(cap_offset + flag_offset + Vec2f(28.0f, -4 + (-16.0f * upgrade_level)));
		tower_flag.SetRelativeZ(-11.0);
	}

	CSpriteLayer@ tower = this.getSpriteLayer("tower");

	if (tower !is null)
	{
		if (upgrade_level > 0)
		{
			tower.SetVisible(true);
			tower.SetOffset(cap_offset + Vec2f(0.0f, 32.0f + (-16.0f * upgrade_level)));
			tower.SetRelativeZ(-10.0);
			tower.animation.frame = (upgrade_level - 1) + (damaged ? 2 : 0);
		}
		else
		{
			tower.SetVisible(false);
		}
	}

	//barracks anim
	{
		CSpriteLayer@ barracks_unbuilt = this.getSpriteLayer("barracks_unbuilt");

		if (barracks_unbuilt !is null)
		{
			if (upgrade_level == 0)
			{
				barracks_unbuilt.SetVisible(true);
			}
			else
			{
				barracks_unbuilt.SetVisible(false);
			}
		}

		CSpriteLayer@ barracks = this.getSpriteLayer("barracks");

		if (barracks !is null)
		{
			if (upgrade_level > 0)
			{
				barracks.SetVisible(true);
				barracks.animation.frame = damaged ? 1 : 0;
			}
			else
			{
				barracks.SetVisible(false);
			}
		}

		CSpriteLayer@ barracks_weapons = this.getSpriteLayer("barracks_weapons");

		if (barracks_weapons !is null)
		{
			if (upgrade_level > 0)
			{
				barracks_weapons.SetVisible(true);
			}
			else
			{
				barracks_weapons.SetVisible(false);
			}
		}

		CSpriteLayer@ barracks_bench = this.getSpriteLayer("barracks_bench");

		if (barracks_bench !is null)
		{
			if (upgrade_level > 1)
			{
				barracks_bench.SetVisible(true);
			}
			else
			{
				barracks_bench.SetVisible(false);
			}
		}
	}

	//upgrade table anim
	if (upgrade_level < 2)
	{
		SetupUpgradeTable(this);
	}
	else
	{
		SetupTunnelLayer(this);
	}

}

void SetupUpgradeTable(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	u8 upgrade_level = blob.get_u8("upgrade_level");

	u16 wood = blob.get_u16("wood");
	u16 oldwood = blob.get_u16("old wood");

	if (oldwood != wood)
	{
		f32 wood_amount = woodForUpgrade(blob);
		f32 upgrade_amount = upgradeAmount(blob, upgrade_level);

		CSpriteLayer@ table = this.getSpriteLayer("upgrade_table");
		if (table !is null)
		{
			if (wood_amount > 0)
			{
				table.SetVisible(true);
				table.animation.frame = Maths::Floor(wood_amount / upgrade_amount * 2.9f);
			}
			else
			{
				table.SetVisible(false);
			}
		}

		blob.set_u16("old wood", wood);
	}
}

void SetupTunnelLayer(CSprite@ this)
{
	CSpriteLayer@ table = this.getSpriteLayer("upgrade_table");
	if (table !is null)
	{
		table.SetVisible(false);
	}

	CSpriteLayer@ tunnel = this.getSpriteLayer("tunnel");
	if (tunnel !is null)
	{
		tunnel.SetVisible(false);
	}
}

#include "MakeParticleSplash.as";
#include "MakeDustParticle.as";
void onGib(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();

	s32 team = blob.getTeamNum();
	f32 sign = blob.isFacingLeft() ? 1.0f : -1.0f;

	MakeParticleSplash("WAR_Base.png", 0, 4, pos + Vec2f(sign * 32, -8),   4.0f, team);
	MakeParticleSplash("WAR_Base.png", 1, 4, pos + Vec2f(0, 0),            3.0f, team);
	MakeParticleSplash("WAR_Base.png", 2, 4, pos + Vec2f(sign * -32, 0),   3.0f, team);

	MakeParticleSplash("WAR_Base.png", 1, 4, pos + Vec2f(0, -32),      2.0f, team);

	MakeParticleSplash("WAR_Base.png", 3, 4, pos + Vec2f(sign * 64, 0),    3.0f, team);
	MakeParticleSplash("WAR_Base.png", 4, 4, pos + Vec2f(sign * 96, 0),    2.0f, team);

	//TODO make dust/smoke
	//for (int i = 0; i < 20; i++)
	//MakeDustParticle(pos + Vec2f(XORRandom(64) + (sign * 32)), "" );

}

//seed helpers

void MakeSeedMenu(CBlob@ this, CBlob@ caller)
{
	if (caller is null)
	{
		return;
	}

	bool hasGrain = (caller.getInventory().getItem("grain") !is null);
	CGridMenu@ menu = CreateGridMenu(caller.getScreenPos() + Vec2f(0, -50), this, Vec2f(hasGrain ? 4 : 3, 1), "Seed nursery");

	if (menu !is null)
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());

		u8 num;
		num = this.get_u8("seed grain amount");
		{
			CGridButton@ button = menu.AddButton("$food$", "Grain Seeds", this.getCommandID("seed grain"), params);

			if (button !is null)
			{
				button.SetNumber(num);
				button.SetEnabled(num > 0);
			}
		}
		num = this.get_u8("seed pine amount");
		{
			CGridButton@ button = menu.AddButton("$tree_pine$", "Pine Tree Seeds", this.getCommandID("seed pine"), params);

			if (button !is null)
			{
				button.SetNumber(num);
				button.SetEnabled(num > 0);
			}
		}
		num = this.get_u8("seed bushy amount");
		{
			CGridButton@ button = menu.AddButton("$tree_bushy$", "Oak Tree Seeds", this.getCommandID("seed bushy"), params);

			if (button !is null)
			{
				button.SetNumber(num);
				button.SetEnabled(num > 0);
			}
		}

		// make seeds from grain

		if (hasGrain)
		{
			CGridButton@ button = menu.AddButton("$grain$", "Make seeds from grain", this.getCommandID("convert grain"), params);
		}
	}
}

void ConvertGrainIntoSeed(CBlob@ this, CBlob@ caller)
{
	if (caller is null)
	{
		return;
	}

	CInventory@ inv = caller.getInventory();
	CBlob@ grainBlob = inv.getItem("grain");

	while (grainBlob !is null)
	{
		u8 amount = this.get_u8("seed grain amount");
		this.set_u8("seed grain amount", amount + 5);
		caller.server_PutOutInventory(grainBlob);
		grainBlob.server_Die();
		@grainBlob = inv.getItem("grain");
	}

	this.Sync("seed grain amount", true);
}

// inventory

//bool isInventoryAccessible( CBlob@ this, CBlob@ forBlob )
//{
//	return canUseWorkbench( this, null);
//}

void PickUpIntoStorage(CBlob@ this)
{
	CBlob@[] blobsInRadius;
	CMap@ map = this.getMap();
	if (map.getBlobsInRadius(this.getPosition(), this.getRadius() * 2.4f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			const string name = b.getName();
			if (b !is this && !b.isInInventory() && !b.isAttached() && b.isOnGround()
			        && (b.hasTag("material") /*|| b.hasTag("food")*/ || name == "grain")
			        && !map.rayCastSolid(this.getPosition(), b.getPosition()))
			{
				this.server_PutInInventory(b);
			}
		}
	}
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().PlaySound("/BaseTake");
}
