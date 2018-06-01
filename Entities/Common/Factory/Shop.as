//generic shop menu

// properties:
//      shop offset - Vec2f - used to offset things bought that spawn into the world, like vehicles

#include "ShopCommon.as"
#include "Requirements_Tech.as"
#include "MakeCrate.as"
#include "CheckSpam.as"

void onInit(CBlob@ this)
{
	this.addCommandID("shop menu");
	this.addCommandID("shop buy");
	this.addCommandID("shop made item");

	if(!this.exists("shop available"))
		this.set_bool("shop available", true);
	if(!this.exists("shop offset"))
		this.set_Vec2f("shop offset", Vec2f_zero);
	if(!this.exists("shop menu size"))
		this.set_Vec2f("shop menu size", Vec2f(7, 7));
	if(!this.exists("shop description"))
		this.set_string("shop description", "Workbench");
	if(!this.exists("shop icon"))
		this.set_u8("shop icon", 15);
	if(!this.exists("shop offset is buy offset"))
		this.set_bool("shop offset is buy offset", false);

	if(!this.exists("shop button radius"))
	{
		CShape@ shape = this.getShape();
		if(shape !is null)
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
	ShopItem[]@ shop_items;
	if(!this.get(SHOP_ARRAY, @shop_items))
	{
		return;
	}

	if(shop_items.length > 0 && this.get_bool("shop available") && !this.hasTag("shop disabled"))
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());

		CButton@ button = caller.CreateGenericButton(
		this.get_u8("shop icon"),                   // icon token
		this.get_Vec2f("shop offset"),              // button offset
		this,                                       // button attachment
		this.getCommandID("shop menu"),             // command id
		getTranslatedString(this.get_string("shop description")),        // description
		params);                                    // bit stream

		button.enableRadius = this.get_u8("shop button radius");
	}
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

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();

	if (cmd == this.getCommandID("shop menu"))
	{
		if (this.hasTag("shop disabled"))
			return;

		// build menu for them
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		BuildShopMenu(this, caller, this.get_string("shop description"), Vec2f(0, 0), this.get_Vec2f("shop menu size"));
	}
	else if (cmd == this.getCommandID("shop buy"))
	{
		if (this.hasTag("shop disabled"))
			return;

		u16 callerID;
		if (!params.saferead_u16(callerID))
			return;
		bool spawnToInventory = params.read_bool();
		bool spawnInCrate = params.read_bool();
		bool producing = params.read_bool();
		string blobName = params.read_string();
		u8 s_index = params.read_u8();

		CBlob@ caller = getBlobByNetworkID(callerID);
		if (caller is null) { return; }
		CInventory@ inv = caller.getInventory();

		if (inv !is null && isInRadius(this, caller))
		{
			ShopItem[]@ shop_items;
			if (!this.get(SHOP_ARRAY, @shop_items)) { return; }
			if (s_index >= shop_items.length) { return; }
			ShopItem@ s = shop_items[s_index];

			// production?
			if (s.ticksToMake > 0)
			{
				s.producing = producing;
				return;
			}

			// check spam

			//if (isSpammed( blobName, this.getPosition(), 12 ))
			//{
			//	if (caller.isMyPlayer())
			//	{
			//		client_AddToChat( "There is too many " + blobName + "'s made here sorry." );
			//		this.getSprite().PlaySound("/NoAmmo.ogg" );
			//	}
			//	return;
			//}

			if (!getNet().isServer()) { return; } //only do this on server

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

			if (tookReqs)
			{
				if (s.spawnNothing)
				{
					CBitStream params;
					params.write_netid(caller.getNetworkID());
					params.write_netid(0);
					params.write_string(blobName);
					this.SendCommand(this.getCommandID("shop made item"), params);
				}
				else
				{

					//inv.server_TakeRequirements(s.requirements);
					Vec2f spawn_offset = Vec2f();

					if (this.exists("shop offset")) { Vec2f _offset = this.get_Vec2f("shop offset"); spawn_offset = Vec2f(2*_offset.x, _offset.y); }
					if (this.isFacingLeft()) { spawn_offset.x *= -1; }
					CBlob@ newlyMade = null;

					if (spawnInCrate)
					{
						CBlob@ crate = server_MakeCrate(blobName, s.name, s.crate_icon, caller.getTeamNum(), caller.getPosition());

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
						CBlob@ blob = server_CreateBlob(blobName, caller.getTeamNum(), this.getPosition() + spawn_offset);
						CInventory@ callerInv = caller.getInventory();
						if (blob !is null)
						{
							bool pickable = blob.getAttachments() !is null && blob.getAttachments().getAttachmentPointByName("PICKUP") !is null;
							if (spawnToInventory)
							{
								if (!blob.canBePutInInventory(caller))
								{
									caller.server_Pickup(blob);
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
						CBitStream params;
						params.write_netid(caller.getNetworkID());
						params.write_netid(newlyMade.getNetworkID());
						params.write_string(blobName);
						this.SendCommand(this.getCommandID("shop made item"), params);
					}
				}
			}
		}
	}
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

			params.write_u16(caller.getNetworkID());
			params.write_bool(s_item.spawnToInventory);
			params.write_bool(s_item.spawnInCrate);
			params.write_bool(s_item.producing);
			params.write_string(s_item.blobName);
			params.write_u8(u8(i));


			CGridButton@ button;

			if (s_item.customButton)
				@button = menu.AddButton(s_item.iconName, getTranslatedString(s_item.name), this.getCommandID("shop buy"), Vec2f(s_item.buttonwidth, s_item.buttonheight), params);
			else
				@button = menu.AddButton(s_item.iconName, getTranslatedString(s_item.name), this.getCommandID("shop buy"), params);


			if (button !is null)
			{
				if (s_item.producing)		  // !! no click for production items
					button.clickable = false;

				button.selectOnClick = true;

				bool tookReqs = false;
				CBlob@ storageReq = null;
				// try taking from the caller + this shop first
				CBitStream missing;
				if (hasRequirements_Tech(this.getInventory(), caller.getInventory(), s_item.requirements, missing))
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
					SetItemDescription_Tech(button, this, s_item.requirements, s_item.description, this.getInventory());
				else
				{
					string desc = s_item.description;
					//if (takeReqsFromStorage)
					//	desc += "\n\n(Using resources from team storage)";

					SetItemDescription_Tech(button, caller, s_item.requirements, getTranslatedString(desc), takeReqsFromStorage ? storageReq.getInventory() : this.getInventory());
				}

				//if (s_item.producing) {
				//	button.SetSelected( 1 );
				//	menu.deleteAfterClick = false;
				//}
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


	CControls@ controls = caller.getControls();
	CGridMenu@ menu = CreateGridMenu(caller.getScreenPos() + offset, this, Vec2f(slotsAdd.x, slotsAdd.y), getTranslatedString(description));

	if (menu !is null)
	{
		if (!this.hasTag(SHOP_AUTOCLOSE))
			menu.deleteAfterClick = false;
		addShopItemsToMenu(this, menu, caller);
	}

}

void BuildDefaultShopMenu(CBlob@ this, CBlob @caller)
{
	BuildShopMenu(this, caller, getTranslatedString("Shop"), Vec2f(0, 0), Vec2f(4, 4));
}
