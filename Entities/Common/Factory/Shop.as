//generic shop menu

// properties:
//      shop offset - Vec2f - used to offset things bought that spawn into the world, like vehicles

#include "ShopCommon.as"
#include "Requirements_Tech.as"
#include "MakeCrate.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"

void onInit(CBlob@ this)
{
	if (isClient())
	{
		this.getSprite().PlaySound("/Construct");
	}

	this.addCommandID("shop buy");
	this.addCommandID("shop made item client");

	if (!this.exists("shop available"))
		this.set_bool("shop available", true);
	if (!this.exists("shop offset"))
		this.set_Vec2f("shop offset", Vec2f_zero);
	if (!this.exists("shop menu size"))
		this.set_Vec2f("shop menu size", Vec2f(7, 7));
	if (!this.exists("shop description"))
		this.set_string("shop description", "Workbench");
	if (!this.exists("shop icon"))
		this.set_u8("shop icon", 15);
	if (!this.exists("shop offset is buy offset"))
		this.set_bool("shop offset is buy offset", false);

	if (!this.exists("shop button radius"))
	{
		CShape@ shape = this.getShape();
		if (shape !is null)
		{
			this.set_u8("shop button radius", Maths::Max(this.getRadius(), (shape.getWidth() + shape.getHeight()) / 2));
		}
		else
		{
			this.set_u8("shop button radius", 16);
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || caller.isAttachedTo(this)) return;

	ShopItem[]@ shop_items;
	if (!this.get(SHOP_ARRAY, @shop_items))
	{
		return;
	}

	if (shop_items.length > 0 && this.get_bool("shop available") && !this.hasTag("shop disabled"))
	{
		CButton@ button = caller.CreateGenericButton(
			this.get_u8("shop icon"),                                // icon token
			this.get_Vec2f("shop offset"),                           // button offset
			this,                                                    // shop blob
			createMenu,                                              // func callback
			getTranslatedString(this.get_string("shop description")) // description
		);

		button.enableRadius = this.get_u8("shop button radius");
	}
}


void createMenu(CBlob@ this, CBlob@ caller)
{
	if (this.hasTag("shop disabled"))
		return;

	BuildShopMenu(this, caller, this.get_string("shop description"), Vec2f(0, 0), this.get_Vec2f("shop menu size"));
}

bool isInRadius(CBlob@ this, CBlob @caller)
{
	Vec2f offset = Vec2f_zero;
	if (this.get_bool("shop offset is buy offset"))
	{
		offset = this.get_Vec2f("shop offset");
	}
	return ((this.getPosition() + Vec2f((this.isFacingLeft() ? -2 : 2)*offset.x, offset.y) - caller.getPosition()).Length() < caller.getRadius() / 2 + this.getRadius());
}

void updateShopGUI(CBlob@ shop)
{
	const string caption = getRules().get_string("shop open menu name");
	if (caption == "") { return; }

	const int callerBlobID = getRules().get_netid("shop open menu caller");
	CBlob@ callerBlob = getBlobByNetworkID(callerBlobID);
	if (callerBlob is null) { return; }

	CGridMenu@ menu = getGridMenuByName(caption);
	if (menu is null) { return; }
	
	ShopItem[]@ shop_items;
	if (!shop.get(SHOP_ARRAY, @shop_items) || shop_items is null) { return; }

	if (menu.getButtonsCount() != shop_items.length)
	{
		warn("expected " + menu.getButtonsCount() + " buttons, got " + shop_items.length + " items");
		return;
	}

	for (uint i = 0; i < shop_items.length; ++i)
	{
		ShopItem@ item = @shop_items[i];
		if (item is null) { continue; }

		CGridButton@ button = @menu.getButtonOfIndex(i);
		applyButtonProperties(@shop, @callerBlob, @button, @item);
	}
}

void onTick(CBlob@ shop)
{
	if (isClient() && getRules().exists("shop open menu blob") && getRules().get_netid("shop open menu blob") == shop.getNetworkID())
	{
		updateShopGUI(@shop);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop buy") && isServer())
	{
		if (this.hasTag("shop disabled") || this.getHealth() <= 0) return;

		bool hotkey;
		u8 s_index;

		if (!params.saferead_u8(s_index) || !params.saferead_bool(hotkey))
		{
			return;
		}

		CPlayer@ callerPlayer = getNet().getActiveCommandPlayer();
		if (callerPlayer is null) return;

		CBlob@ caller = callerPlayer.getBlob();
		if (caller is null) return;

		// range check
		if (!isInRadius(this, caller)) return;

		CInventory@ inv = caller.getInventory();
		if (inv is null) return;

		ShopItem[]@ shop_items;

		if (!this.get(SHOP_ARRAY, @shop_items)) return;
		if (s_index >= shop_items.length) return;

		ShopItem@ s = shop_items[s_index];

		bool spawnToInventory, spawnInCrate, producing; 

		spawnToInventory = s.spawnToInventory;
		spawnInCrate = s.spawnInCrate;
		producing = s.producing;

		// production?
		if (s.ticksToMake > 0)
		{
			s.producing = true;
			return;
		}

		bool tookReqs = false;

		// try taking from the caller + this shop first
		CBitStream missing;
		if (hasRequirements_Tech(inv, this.getInventory(), s.requirements, missing))
		{
			server_TakeRequirements(inv, this.getInventory(), s.requirements);
			tookReqs = true;
		}
		// try taking from caller + storages second
		if (!tookReqs)
		{
			const s32 team = this.getTeamNum();
			CBlob@[] storages;
			if (getBlobsByTag("storage", @storages))
			{
				for (uint step = 0; step < storages.length; ++step)
				{
					CBlob@ storage = storages[step];
					if (storage.getTeamNum() == team)
					{
						CBitStream missing;
						if (hasRequirements_Tech(inv, storage.getInventory(), s.requirements, missing))
						{
							server_TakeRequirements(inv, storage.getInventory(), s.requirements);
							tookReqs = true;
							break;
						}
					}
				}
			}
		}

		if (tookReqs)
		{
			if (s.spawnNothing)
			{
				CBitStream params;
				params.write_u16(this.getNetworkID());
				params.write_u16(caller.getNetworkID());
				params.write_u16(0);
				params.write_string(s.blobName);
				params.ResetBitIndex();

				ShopMadeItem@ onShopMadeItem;
				if (this.get("onShopMadeItem handle", @onShopMadeItem))
				{
					onShopMadeItem(params);
				}
				this.SendCommand(this.getCommandID("shop made item client"), params);
			}
			else
			{
				Vec2f spawn_offset = Vec2f();

				if (this.exists("shop offset")) { Vec2f _offset = this.get_Vec2f("shop offset"); spawn_offset = Vec2f(2*_offset.x, _offset.y); }
				if (this.isFacingLeft()) { spawn_offset.x *= -1; }
				CBlob@ newlyMade = null;

				if (spawnInCrate)
				{
					CBlob@ crate = server_MakeCrate(s.blobName, s.name, s.crate_icon, caller.getTeamNum(), caller.getPosition());

					if (crate !is null)
					{
						if (spawnToInventory && caller.canBePutInInventory(crate))
						{
							caller.server_PutInInventory(crate);
						}
						else
						{
							caller.server_Pickup(crate);
						}
						@newlyMade = crate;
					}
				}
				else
				{
					CBlob@ blob = server_CreateBlob(s.blobName, caller.getTeamNum(), this.getPosition() + spawn_offset);
					CInventory@ callerInv = caller.getInventory();
					if (blob !is null)
					{
						bool pickable = blob.getAttachments() !is null && blob.getAttachments().getAttachmentPointByName("PICKUP") !is null;
						if (spawnToInventory)
						{
							if (!blob.canBePutInInventory(caller))
							{
								if (blob.canBePickedUp(caller))
								{
									caller.server_Pickup(blob);
								}
							}
							else if (!callerInv.isFull())
							{
								caller.server_PutInInventory(blob);
							}
							// Hack: Archer Shop can force Archer to drop Arrows.
							else if (this.getName() == "archershop" && caller.getName() == "archer")
							{
								int arrowCount = callerInv.getCount("mat_arrows");
								int stacks = arrowCount / 30;
								// Hack: Depends on Arrow stack size.
								if (stacks > 1)
								{
									CBlob@ arrowStack = caller.server_PutOutInventory("mat_arrows");
									if (arrowStack !is null)
									{
										if (arrowStack.getAttachments() !is null && arrowStack.getAttachments().getAttachmentPointByName("PICKUP") !is null)
										{
											caller.server_Pickup(arrowStack);
										}
										else
										{
											arrowStack.setPosition(caller.getPosition());
										}
									}
									caller.server_PutInInventory(blob);
								}
								else if (pickable)
								{
									caller.server_Pickup(blob);
								}
							}
							else if (pickable)
							{
								caller.server_Pickup(blob);
							}
						}
						else
						{
							CBlob@ carried = caller.getCarriedBlob();
							if (carried is null && pickable)
							{
								caller.server_Pickup(blob);
							}
							else if (blob.canBePutInInventory(caller) && !callerInv.isFull())
							{
								caller.server_PutInInventory(blob);
							}
							else if (pickable)
							{
								caller.server_Pickup(blob);
							}
						}
						@newlyMade = blob;
					}
				}

				if (newlyMade !is null)
				{
					newlyMade.set_u16("buyer", caller.getPlayer().getNetworkID());

					CBitStream params;
					params.write_u16(this.getNetworkID());
					params.write_u16(caller.getNetworkID());
					params.write_u16(newlyMade.getNetworkID());
					params.write_string(s.blobName);
					params.ResetBitIndex();
					ShopMadeItem@ onShopMadeItem;
					if (this.get("onShopMadeItem handle", @onShopMadeItem))
					{
						onShopMadeItem(params);
					}
					this.SendCommand(this.getCommandID("shop made item client"), params);
				}
			}
		}
	}
}

void applyButtonProperties(CBlob@ shop, CBlob@ caller, CGridButton@ button, ShopItem@ s_item)
{
	if (s_item.producing)		  // !! no click for production items
		button.clickable = false;

	button.selectOnClick = true;

	bool tookReqs = false;
	CBlob@ storageReq = null;
	// try taking from the caller + this shop first
	CBitStream missing;
	if (hasRequirements_Tech(shop.getInventory(), caller.getInventory(), s_item.requirements, missing))
	{
		tookReqs = true;
	}
	// try taking from caller + storages second
	//if (!tookReqs)
	//{
	//	const s32 team = this.getTeamNum();
	//	CBlob@[] storages;
	//	if (getBlobsByTag( "storage", @storages ))
	//		for (uint step = 0; step < storages.length; ++step)
	//		{
	//			CBlob@ storage = storages[step];
	//			if (storage.getTeamNum() == team)
	//			{
	//				CBitStream missing;
	//				if (hasRequirements_Tech( caller.getInventory(), storage.getInventory(), s_item.requirements, missing ))
	//				{
	//					@storageReq = storage;
	//					break;
	//				}
	//			}
	//		}
	//}

	const bool takeReqsFromStorage = (storageReq !is null);

	if (s_item.ticksToMake > 0)		   // production
		SetItemDescription_Tech(button, shop, s_item.requirements, s_item.description, shop.getInventory());
	else
	{
		string desc = s_item.description;
		//if (takeReqsFromStorage)
		//	desc += "\n\n(Using resources from team storage)";

		SetItemDescription_Tech(button, caller, s_item.requirements, getTranslatedString(desc), takeReqsFromStorage ? storageReq.getInventory() : shop.getInventory());
	}

	//if (s_item.producing) {
	//	button.SetSelected( 1 );
	//	menu.deleteAfterClick = false;
	//}
}

//helper for building menus of shopitems

void addShopItemsToMenu(CBlob@ this, CGridMenu@ menu, CBlob@ caller)
{
	ShopItem[]@ shop_items;

	if (this.get(SHOP_ARRAY, @shop_items))
	{
		for (uint i = 0 ; i < shop_items.length; i++)
		{
			ShopItem @s_item = shop_items[i];
			if (s_item is null || caller is null) { continue; }
			CBitStream params;

			params.write_u8(u8(i));
			params.write_bool(false); //used hotkey?

			CGridButton@ button;

			if (s_item.customButton)
				@button = menu.AddButton(s_item.iconName, getTranslatedString(s_item.name), this.getCommandID("shop buy"), Vec2f(s_item.buttonwidth, s_item.buttonheight), params);
			else
				@button = menu.AddButton(s_item.iconName, getTranslatedString(s_item.name), this.getCommandID("shop buy"), params);
			
			if (button !is null)
			{
				applyButtonProperties(@this, @caller, @button, @s_item);
			}
		}
	}
}

void BuildShopMenu(CBlob@ this, CBlob @caller, string description, Vec2f offset, Vec2f slotsAdd)
{
	if (caller is null || !caller.isMyPlayer())
		return;

	ShopItem[]@ shopitems;

	if (!this.get(SHOP_ARRAY, @shopitems)) { return; }

	const string caption = getTranslatedString(description);

	CControls@ controls = caller.getControls();
	CGridMenu@ menu = CreateGridMenu(caller.getScreenPos() + offset, this, Vec2f(slotsAdd.x, slotsAdd.y), caption);

	getRules().set_netid("shop open menu blob", this.getNetworkID());
	getRules().set_string("shop open menu name", caption);
	getRules().set_netid("shop open menu caller", caller.getNetworkID());

	if (menu !is null)
	{
		if (!this.hasTag(SHOP_AUTOCLOSE))
			menu.deleteAfterClick = false;
		addShopItemsToMenu(this, menu, caller);

		//keybinds
		array<EKEY_CODE> numKeys = { KEY_KEY_1, KEY_KEY_2, KEY_KEY_3, KEY_KEY_4, KEY_KEY_5, KEY_KEY_6, KEY_KEY_7, KEY_KEY_8, KEY_KEY_9, KEY_KEY_0 };
		uint keybindCount = Maths::Min(shopitems.length(), numKeys.length());

		for (uint i = 0; i < keybindCount; i++)
		{
			CBitStream params;
			params.write_u8(i);
			params.write_bool(true); //used hotkey?

			menu.AddKeyCommand(numKeys[i], this.getCommandID("shop buy"), params);
		}
	}

}

void BuildDefaultShopMenu(CBlob@ this, CBlob @caller)
{
	BuildShopMenu(this, caller, getTranslatedString("Shop"), Vec2f(0, 0), Vec2f(4, 4));
}
