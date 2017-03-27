// Trading Post

#include "MakeCrate.as";
#include "MakeSeed.as";
#include "Requirements.as"
#include "TradingCommon.as"
#include "Descriptions.as";
#include "WARCosts.as";

const int DROP_SECS = 8;

void onInit(CBlob@ this)
{
	this.addCommandID("stock");
	this.addCommandID("buy");
	this.addCommandID("reload menu");
	AddIconToken("$" + this.getName() + "$", "TradingPost.png", Vec2f(16, 16), 15);
	AddIconToken("$parachute$", "Crate.png", Vec2f(32, 32), 4);
	AddIconToken("$trade$", "MaterialIcons.png", Vec2f(16, 16), 5);

	AddIconToken("$MENU_INDUSTRY$", "TradingMenuIndustry.png", Vec2f(72, 24), 0);
	AddIconToken("$MENU_SIEGE$", "TradingMenuSiege.png", Vec2f(72, 24), 0);
	AddIconToken("$MENU_NAVAL$", "TradingMenuNaval.png", Vec2f(72, 24), 0);
	AddIconToken("$MENU_KITS$", "TradingMenuKits.png", Vec2f(72, 24), 0);
	AddIconToken("$MENU_OTHER$", "TradingMenuOther.png", Vec2f(72, 24), 0);
	AddIconToken("$MENU_GENERIC$", "TradingMenuGeneric.png", Vec2f(72, 24), 0);
	AddIconToken("$MENU_TECHS$", "TradingMenuTechs.png", Vec2f(72, 24), 0);
	AddIconToken("$MENU_MATERIAL$", "TradingMenuMaterial.png", Vec2f(72, 24), 0);
	AddIconToken("$MENU_MAGIC$", "TradingMenuMagic.png", Vec2f(72, 24), 0);

	// shipment vars
	this.set_u32("next drop time", 0);
	this.set_u32("drop secs", DROP_SECS);
	this.set_u8("drop team", this.getTeamNum());
	uint[] shipment;
	this.set("shipment", shipment);

	this.Tag("trader");

	this.getCurrentScript().tickFrequency = 31;
}

void onTick(CBlob@ this)
{
	// drop crate
	u32 nextDropTime = this.get_u32("next drop time");
	if (getGameTime() >= nextDropTime)
	{
		Ship(this);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!this.hasTag("dead"))
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		caller.CreateGenericButton("$trade$", Vec2f_zero, this, this.getCommandID("stock"), "Shop", params);
	}
}

void BuildTradingMenu(CBlob@ this, CBlob @caller)
{
	TradeItem[]@ items;
	this.get("items", @items);

	if (caller !is null && caller.isMyPlayer() && items !is null)
	{
		CGridMenu@ menu = CreateGridMenu(this.getScreenPos() + Vec2f(0.0f, 0.0f), this, this.get_Vec2f("trade menu size"), this.get_string("trade menu caption"));
		if (menu !is null)
		{
			addTradeItemsToMenu(this, menu, caller.getNetworkID());
			menu.deleteAfterClick = false;
		}
	}
}

void addTradeItemsToMenu(CBlob@ this, CGridMenu@ menu, u16 callerID)
{
	TradeItem[]@ items;

	if (this.get("items", @items))
	{
		CBlob@ caller = getBlobByNetworkID(callerID);
		const u32 gametime = getGameTime();

		for (uint i = 0 ; i < items.length; i++)
		{
			TradeItem @item = items[i];

			if (item.isSeparator)
			{
				CGridButton@ separator = menu.AddButton(item.iconName, "", item.separatorIconSize);
				if (separator !is null)
				{
					separator.clickable = false;
				}
			}
			else
			{
				CBitStream params;
				params.write_u16(callerID);
				params.write_u8(i);
				const u16 goldCount = caller.getBlobCount("mat_gold");
				params.write_u16(goldCount);

				CGridButton@ button = menu.AddButton(item.iconName, item.name, this.getCommandID("buy"), params);
				if (button !is null)
				{
					if (item.boughtTime != 0 && item.boughtTime + item.unavailableTime > gametime)
					{
						button.hoverText = "Out of stock. Come back later.";
						button.SetEnabled(false);
					}
					else
					{
						SetItemDescription(button, caller, item.reqs, item.description);

						if (item.prepaidGold)
						{
							if (goldCount > 0)
							{
								button.SetEnabled(true);
							}

							if (item.paidGold > 0)
							{
								button.SetNumber(item.paidGold);
								button.hoverText += "\n\n (" + item.paidGold + " paid already)";
							}
						}
					}
				}
			}
		}
	}
}

bool isInRadius(CBlob@ this, CBlob @caller)
{
	return (!this.hasTag("dead") && (this.getPosition() - caller.getPosition()).Length() < this.getRadius() * 4.0f + caller.getRadius());
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("stock"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		BuildTradingMenu(this, caller);
	}
	else if (cmd == this.getCommandID("buy"))
	{
		u16 callerid = params.read_u16();
		u8 itemIndex = params.read_u8();
		u16 goldCount = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(callerid);

		if (caller !is null)
		{
			if (!isInRadius(this, caller))
			{
				caller.ClearMenus();
				return;
			}

			TradeItem@ item = AddItemToShip(this, caller, itemIndex, goldCount);

			if (item is null) // reload menu
			{
				caller.ClearMenus();
				BuildTradingMenu(this, caller);
			}
		}
	}
	else if (cmd == this.getCommandID("reload menu"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			caller.ClearMenus();
			BuildTradingMenu(this, caller);
		}
	}
}

TradeItem@ AddItemToShip(CBlob@ this, CBlob@ caller, const uint itemIndex, const u16 goldCount)
{
	if (caller is null)
		return null;

	TradeItem[]@ items;

	if (this.get("items", @items) && caller !is null && itemIndex >= 0 && itemIndex < items.length)  {}
	else
	{
		warn("tradingmenu.as: no items");
		return null;
	}

	TradeItem@ item = items[ itemIndex ];
	CInventory@ inv = caller.getInventory();

	if (inv is null || item is null)
	{
		warn("tradingmenu.as: item or caller inv null");
		return null;
	}

	CBitStream missing;

	// *begin* mod prices for paid
	CBitStream modReqs;
	modReqs = item.reqs;

	if (item.prepaidGold)
	{
		modReqs.ResetBitIndex();
		if (modReqs.getBytesUsed() > 0)
		{
			modReqs.read_string();
			modReqs.read_string();
			modReqs.read_string();
			u16 q = modReqs.read_u16();
			modReqs.ResetBitIndex();
			modReqs.read_string();
			modReqs.read_string();
			modReqs.read_string();
			modReqs.write_u16(q - item.paidGold);
		}
		//modReqs.SetBitIndex( modReqs.getBitIndex() - 2*8 ); crashes
	}
	// *end* mod prices for paid

	if (hasRequirements(inv, modReqs, missing))
	{
		server_TakeRequirements(inv, modReqs);
	}
	else
	{
		// get gold	.. hacks...
		string text, requiredType, name, friendlyName;
		u16 quantity = 0;
		if (item.prepaidGold) // HACK
		{
			missing.ResetBitIndex();
			while (!missing.isBufferEnd())
			{
				ReadRequirement(missing, requiredType, name, friendlyName, quantity);
				if (name == "mat_gold")
				{
					item.paidGold += goldCount;
					server_TakeRequirements(inv, modReqs);
					this.getSprite().PlaySound("/Cha.ogg");
				}
			}
		}
		return null;
	}

	if (item.instantShipping)
	{
		CBlob@ blob = MakeBlobFromItem(item);
		if (blob !is null)
		{
			blob.server_setTeamNum(caller.getTeamNum());
			if (!item.buyIntoInventory || !caller.server_PutInInventory(blob))
			{
				caller.server_Pickup(blob);
			}
		}
	}
	else
	{
		uint[]@ shipment;
		this.get("shipment", @shipment);

		if (shipment.length == 0 && getNet().isServer())
		{
			// new shipment - start countdown
			this.set_u32("next drop time", getGameTime() + this.get_u32("drop secs") * getTicksASecond());
			this.Sync("next drop time", true);
			this.set_u8("drop team", caller.getTeamNum());
		}

		shipment.push_back(itemIndex);
	}

	item.boughtTime = getGameTime();

	this.getSprite().PlaySound("/ChaChing.ogg");

	return item;
}

void Ship(CBlob@ this)
{
	uint[]@ shipment;

	if (this.get("shipment", @shipment) && shipment.length > 0)
	{
		if (getNet().isServer())
		{
			RecursiveCrate(this, shipment, 0, null);
		}

		shipment.clear();
	}
}

void RecursiveCrate(CBlob@ this, uint[]@ shipment, uint index, CBlob@ itemThatDidntFit)
{
	if (index < shipment.length || itemThatDidntFit !is null)
	{
		TradeItem[]@ items;

		if (!this.get("items", @items))
		{
			warn("Trading post: no items");
			return;
		}

		CBlob@ crate = server_MakeCrateOnParachute("", "", 0, this.get_u8("drop team"), getDropPosition(this.getPosition()));

		if (crate !is null)
		{
			if (itemThatDidntFit !is null)
				if (!crate.server_PutInInventory(itemThatDidntFit))
				{
					// doesn't fit at all - spawn a dedicated crate
					string configName = itemThatDidntFit.getName();
					server_MakeCrateOnParachute(configName, itemThatDidntFit.getInventoryName(), 1 + XORRandom(2), this.get_u8("drop team"), getDropPosition(this.getPosition()));
					itemThatDidntFit.server_Die();

					if (index >= shipment.length) // destroy crates if nothing more left
					{
						crate.server_Die();
					}
				}

			// put stuff in crate recursively until all items used

			for (uint i = index; i < shipment.length; i++)
			{
				TradeItem@ item = items[shipment[i]];
				CBlob@ blobItem = MakeBlobFromItem(item);

				if (blobItem !is null)
				{
					if (!crate.server_PutInInventory(blobItem))
					{
						if (crate.getInventory().getItemsCount() == 0)
						{
							crate.server_Die();
						}

						RecursiveCrate(this, shipment, i + 1, blobItem);
						return;
					}
				}
			}
		}
	}
}

CBlob@ MakeBlobFromItem(TradeItem@ item)
{
	if (item.configFilename == "scroll")
	{
		return server_MakePredefinedScroll(Vec2f_zero, item.scrollName);
	}
	else
	{
		return MakeItem(item.configFilename);
	}
}

CBlob@ MakeItem(const string& in name)
{
	string[]@ tokens = name.split(" ");

	if (tokens.length > 1 && tokens[0] == "seed")   // seed ...
	{
		return server_MakeSeed(Vec2f_zero, tokens[1]);
	}
	else
	{
		return server_CreateBlob(name);      // normal blob
	}
}

// SYNC

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	TradeItem[]@ items;
	if (this.get("items", @items))
	{
		stream.write_u8(items.length);
		for (uint i = 0 ; i < items.length; i++)
		{
			TradeItem @item = items[i];
			item.Serialise(stream);
		}
	}
	else
		stream.write_u8(0);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	u8 itemsCount;
	if (!stream.saferead_u8(itemsCount))
	{
		warn("trading: failed to read itemsCount");
		return false;
	}

	TradeItem[]@ items;
	if (!this.get("items", @items))
	{
		CreateTradeMenu(this, this.get_Vec2f("trade menu size"), this.get_string("trade menu caption"));
	}

	if (this.get("items", @items))
	{
		items.clear();
		for (uint i = 0 ; i < itemsCount; i++)
		{
			TradeItem item;
			if (!item.Unserialise(stream))
			{
				warn("Could not receive trade item for " + this.getName());
				continue;
			}
			items.push_back(item);
		}

		return true;
	}
	else
	{
		warn("could not create trading menu");
		return false;
	}
}

// SPRITE


// render countdown

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	Vec2f pos2d = blob.getScreenPos();
	s32 nextDropTime = blob.get_u32("next drop time");
	u32 gameTime = getGameTime();
	s32 dropTime = Maths::Max(0, gameTime - 60);

	if (nextDropTime > dropTime)
	{
		// draw drop time progress bar
		int top = pos2d.y - 2.5f * blob.getHeight() - 50.0f + 7.0f * Maths::Sin((getGameTime() + blob.getNetworkID()) / 7.0f);  // bounce a bit
		int margin = 7;
		Vec2f dim;
		int secs = 1 + (nextDropTime - gameTime + 60) / getTicksASecond();
		string label = "Next drop in " + secs + "s";
		GUI::SetFont("menu");		
		GUI::GetTextDimensions(label , dim);
		dim.x += margin;
		dim.y += margin;
		dim.y *= 1.8f;
		Vec2f upperleft(pos2d.x - dim.x / 2, top - 2 * dim.y);
		Vec2f lowerright(pos2d.x + dim.x / 2, top - dim.y);
		f32 progress = 1.0f - (float(secs - 1) / float(blob.get_u32("drop secs")));
		GUI::DrawProgressBar(upperleft, lowerright, progress);
		GUI::DrawIconByName("$parachute$", Vec2f(upperleft.x + 26.0f, upperleft.y - 8.0f));
		// draw items waiting for shipment
		CBlob@ localBlob = getLocalPlayerBlob();

		if (localBlob !is null && (
		            // ((localBlob.getPosition() - blob.getPosition()).Length() < (localBlob.getRadius() + blob.getRadius())) &&
		            (getHUD().hasButtons())))
		{
			TradeItem[]@ items;

			if (!blob.get("items", @items))
			{
				warn("Trading post: no items");
				return;
			}

			uint[]@ shipment;
			blob.get("shipment", @shipment);

			for (uint i = 0; i < shipment.length; i++)
			{
				int top2 = top - 2 * dim.y;
				Vec2f upperleft(pos2d.x - dim.x - dim.x / 3.0f , top2 + i * dim.y);
				Vec2f lowerright(upperleft.x + dim.x / 2.0f, top2 + dim.y + i * dim.y);
				// above the screen?  temp shitty code
				uint tooMuch = 8;

				if (i > tooMuch)
				{
					f32 height = lowerright.y - upperleft.y;
					upperleft.Set(upperleft.x - dim.x / 2.0f, top2 + (i - tooMuch - 1)*dim.y);
					lowerright.Set(lowerright.x - dim.x / 2.0f, top2 + dim.y + (i - tooMuch - 1)*dim.y);
				}

				Vec2f iconDim;
				const string iconName = items[shipment[i]].iconName;
				GUI::GetIconDimensions(iconName, iconDim);
				GUI::DrawSunkenPane(upperleft, lowerright);
				GUI::DrawIconByName(iconName, Vec2f(upperleft.x + 32.0f - iconDim.x, upperleft.y + 16.0f - iconDim.y));
			}
		}
	}
}
