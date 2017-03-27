// Factory

#include "ShopCommon.as";
#include "ProductionCommon.as";
#include "TechsCommon.as";
#include "Descriptions.as";
#include "Requirements_Tech.as";
#include "MakeScroll.as";
#include "Help.as";
#include "WARCosts.as";
#include "Hitters.as";
#include "HallCommon.as";

const string children_destructible_tag = "children destructible";
const string children_destructible_label = "children destruct label";

bool hasTech(CBlob@ this)
{
	return this.get_string("tech name").size() > 0;
}

void onInit(CBlob@ this)
{
	this.Tag("huffpuff production");   // for production.as

	AddIconToken("$take_scroll$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 19, 1);

	this.addCommandID("upgrade factory menu");
	this.addCommandID("upgrade factory");
	this.addCommandID("kill children");
	this.addCommandID("pause production");
	this.addCommandID("unpause production");

	AddIconToken("$kill_children$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 10, 1);

	this.set_TileType("background tile", CMap::tile_wood_back);

	SetHelp(this, "help use", "builder", "$workshop$Convert workshop    $KEY_E$", "", 3);

	if (hasTech(this))
	{
		AddProductionItemsFromTech(this, this.get_string("tech name"));
	}

	this.set_u8("population usage", (getNet().isServer() && getNet().isClient()) ? 1 : 1);
	this.set_Vec2f("production offset", Vec2f(-8.0f, 0.0f));
}

int getWorkers(CBlob@ this)
{
	int workers = 0;
	CBlob@[] blobs;
	if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius(), @blobs))
	{
		for (uint step = 0; step < blobs.length; ++step)
		{
			CBlob@ b = blobs[step];
			if (b.hasTag("migrant") && !b.hasTag("dead"))
			{
				workers++;
			}
		}
	}
	return workers;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	// add button for adding scroll if caller has it

	CBitStream params;
	params.write_u16(caller.getNetworkID());


	if (!hasTech(this) && caller.isOverlapping(this))
	{
		caller.CreateGenericButton(12, Vec2f(0, 0), this, this.getCommandID("upgrade factory menu"), "Convert Workshop", params);
	}
	else
	{
		if (getWorkers(this) == 0)
		{
			CButton@ button = caller.CreateGenericButton("$migrant$", Vec2f(0, 0), this, 0, "Requires a free worker from Hall");
			if (button !is null)
			{
				button.SetEnabled(false);
			}
		}
		//else
		//if (caller.getTeamNum() == this.getTeamNum() && caller.isOverlapping(this)) //destroy applicable items
		//{
		//	string[] destructibleChildren = ChildDestruction(this, false);
		//	uint length = destructibleChildren.length;
		//	if (length > 0)
		//	{
		//		this.Tag(children_destructible_tag);
		//		string caption = "Destroy Far Items:";
		//		for (uint i = 0; i < length; ++i)
		//		{
		//			caption += "\n"+destructibleChildren[i];
		//		}

		//		caller.CreateGenericButton( "$kill_children$", Vec2f(0, -20), this, this.getCommandID("kill children"), caption, params );
		//	}
		//}
	}
}

void BuildUpgradeMenu(CBlob@ this, CBlob@ caller)
{
	ScrollSet@ all = getScrollSet("all scrolls");
	if (caller !is null && caller.isMyPlayer() && all !is null)
	{
		caller.ClearMenus();
		//caller.Tag("dont clear menus"); // dont clear menus in StandardControls.as

		CControls@ controls = caller.getControls();
		int size = Maths::Sqrt(all.names.length);
		CGridMenu@ menu = CreateGridMenu(caller.getScreenPos() + Vec2f(0.0f, 50.0f), this, Vec2f(size, size - 1), "Upgrade to...");
		if (menu !is null)
		{
			menu.deleteAfterClick = true;
			AddButtonsForSet(this, menu, all);
		}
	}
}

void AddButtonsForSet(CBlob@ this, CGridMenu@ menu, ScrollSet@ set)
{
	if (set is null)
		return;

	CInventory@ inv = this.getInventory();
	for (uint i = 0; i < set.names.length; i++)
	{
		const string defname = set.names[i];
		ScrollDef@ def;
		set.scrolls.get(defname, @def);
		if (def !is null && def.level >= 0.0f && def.items.length > 0)
		{
			CBitStream params;
			params.write_string(defname);
			CGridButton@ button = menu.AddButton("MiniIcons.png", def.scrollFrame, Vec2f(16, 16), def.name, this.getCommandID("upgrade factory"), Vec2f(1, 1), params);
			if (button !is null)
			{
				CBitStream reqs, missing;
				AddRequirement(reqs, "tech", defname, def.name);
				if (!hasRequirements_Tech(inv, reqs, missing))
				{
					button.SetEnabled(false);
					button.hoverText = "Convert Workshop\n";
					button.hoverText += "\n$RED$Requires " + def.name + "\n from Hall\n$RED$            $RESEARCH$\n\n";
				}
				else
				{
					// set number of already made factories of this kind
					const s32 team = this.getTeamNum();
					int sameFactoryCount = 0;
					CBlob@[] factories;
					if (getBlobsByName("factory", @factories))
					{
						for (uint step = 0; step < factories.length; ++step)
						{
							CBlob@ factory = factories[step];
							if (factory.getTeamNum() == team)
							{
								const string factoryTechName = factory.get_string("tech name");
								if (factoryTechName == defname)
								{
									sameFactoryCount++;
								}
							}
						}
					}

					button.SetNumber(sameFactoryCount);
				}
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();

	//
	if (cmd == this.getCommandID("upgrade factory menu"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		BuildUpgradeMenu(this, caller);
	}
	else if (cmd == this.getCommandID("upgrade factory"))
	{
		if (this.get_string("tech name").size() == 0)
		{
			const string defname = params.read_string();
			this.set_string("tech name", defname);
			AddProductionItemsFromTech(this, defname);
			this.getSprite().PlaySound("/ConstructShort.ogg");

			if (isServer)
			{
				if (this.get_u8("migrants count") > 0 || this.hasTag(worker_tag))
				{
					this.SendCommand(this.getCommandID("unpause production"));
				}
				else
				{
					this.SendCommand(this.getCommandID("pause production"));
				}
			}
		}
	}
	else if (cmd == this.getCommandID("kill children"))
	{
		if (isServer)
		{
			string[] names = ChildDestruction(this, true);
			if (names.length == 0)
				getNet().server_SendMsg("Team mates are near the item you want destroyed."); //TODO: make this less spammy
		}
	}
	else if (cmd == this.getCommandID("pause production") || (hasTech(this) && cmd == this.getCommandID(worker_out_cmd)))
	{
		this.Tag("production paused");
		this.getSprite().PlaySound("/PowerDown.ogg");

	}
	else if (cmd == this.getCommandID("unpause production") || (hasTech(this) && cmd == this.getCommandID(worker_in_cmd)))
	{
		this.Untag("production paused");
		this.getSprite().PlaySound("/PowerUp.ogg");
	}

}

string[] ChildDestruction(CBlob@ this, bool kill_kids)
{
	bool killed = false;
	bool server = getNet().isServer();

	int team = this.getTeamNum();

	string[] names;

	u16[]@ ids;
	if (this.get(PRODUCTION_TRACKING_ARRAY, @ids))
	{
		for (uint i = 0; i < ids.length; i++)
		{
			CBlob@ blob = getBlobByNetworkID(ids[i]);
			if (blob !is null)
			{
				if (!hasTeamiesNear(blob, team))
				{
					if (kill_kids && server)
					{
						this.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), 100, Hitters::crush, true);
					}

					names.push_back(blob.getInventoryName());
				}
			}
		}
	}

	return names;
}

bool hasTeamiesNear(CBlob@ blob, int team)
{
	CMap@ map = blob.getMap();
	if (map is null) return false;

	Vec2f pos = blob.getPosition();

	CBlob@[] blobs;
	if (map.getBlobsInRadius(pos, 128.0f, @blobs))
	{
		for (uint step = 0; step < blobs.length; ++step)
		{
			CBlob@ b = blobs[step];
			if (b !is blob && //not us
			        b.getTeamNum() == team && //same team
			        b.hasTag("player"))
			{
				return true;
			}
		}
	}

	return false;
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return false;
}

void AddProductionItemsFromTech(CBlob@ this, const string &in defname)
{
	ScrollSet@ set = getScrollSet("all scrolls");
	ScrollDef@ def;
	set.scrolls.get(defname, @def);
	if (def !is null)
	{
		RemoveProductionItems(this);

		for (uint i = 0 ; i < def.items.length; i++)
		{
			ShopItem @item = def.items[i];
			ShopItem@ s = addProductionItem(this, item.name, item.iconName, item.blobName, item.description, 1, item.spawnInCrate, item.quantityLimit, item.requirements);
			if (s !is null)
			{
				s.ticksToMake = item.ticksToMake * getTicksASecond();
			}
		}

		this.set_string("tech name", defname);
		this.setInventoryName(def.name + " Factory");
		this.inventoryIconFrame = def.scrollFrame;

		if (getNet().isClient())
		{
			RemoveHelps(this, "help use");
			SetHelp(this, "help use", "", "Check production    $KEY_E$", "", 2);
		}
	}
}

void RemoveProductionItems(CBlob@ this)
{
	this.clear(TECH_ARRAY);
	this.clear(PRODUCTION_ARRAY);
	this.inventoryIconFrame = 0;
}

// leave a pile of wood	after death
void onDie(CBlob@ this)
{
	if (getNet().isServer())
	{
		CBlob@ blob = server_CreateBlob("mat_wood", this.getTeamNum(), this.getPosition());
		if (blob !is null)
		{
			blob.server_SetQuantity(COST_WOOD_FACTORY / 2);
		}
	}
}



