// Bolter.as

#include "MechanismsCommon.as";
#include "GenericButtonCommon.as";

class Magazine : Component
{
	Magazine(Vec2f position)
	{
		x = position.x;
		y = position.y;
	}
}

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);

	this.addCommandID("load");
	this.addCommandID("unload");
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f position = this.getPosition() / 8;
	const u16 angle = this.getAngleDegrees();

	Magazine component(position);
	this.set("component", component);

	if (isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_CARDINAL,                      // input topology
		TOPO_CARDINAL,                      // output topology
		INFO_NONE,                          // information
		0,                                  // power
		0);                                 // id
	}

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.SetZ(500);
	sprite.SetFacingLeft(false);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (this.getDistanceTo(caller) > 16.0f || !this.getShape().isStatic()) return;

	CBlob@ carried = caller.getCarriedBlob();
	bool LOAD = carried !is null;

	CBlob@ item = this.getInventory().getItem(0);

	if (LOAD)
	{
		if 	(!carried.canBePutInInventory(this) 			// doesn't go in inventories to begin with
			|| !this.getInventory().canPutItem(carried)  	// does go in inventories but doesn't fit
			|| (item !is null && (item.getName() != carried.getName() || item.getQuantity() == item.maxQuantity)))
		{
			return;
		}
	}
	else if (item is null)
	{
		return;
	}
		
	CBlob@ target = LOAD ? carried : item;
	string iconName = "$" + target.getName() + "$";
	if (GUI::hasIconName("$" + target.getInventoryName() + "$"))
	{
		iconName = "$" + target.getInventoryName() + "$";
	}

	CButton@ button = caller.CreateGenericButton(
	iconName, 																									// icon token
	Vec2f_zero,																									// button offset
	this, 																										// button attachment
	this.getCommandID(LOAD ? "load" : "unload"), 																// command id
	getTranslatedString(LOAD ? "Load {ITEM}" : "Unload {ITEM}").replace("{ITEM}", target.getInventoryName()));	// description
		
	button.radius = 8.0f;
	button.enableRadius = 22.0f;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("load") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;
					
		CBlob@ caller = player.getBlob();
		if (caller is null) return;

		// range check
		if (this.getDistanceTo(caller) > 22.0f) return;

		CBlob@ carried = caller.getCarriedBlob();
		if (carried is null) return;

		CBlob@ item = this.getInventory().getItem(0);
		if (item is null)
		{
			this.server_PutInInventory(carried);
		}
		else
		{
			// double check
			if (item.getName() != carried.getName() || item.getQuantity() == item.maxQuantity) return;

			const u16 quantity_stored = item.getQuantity();
			const u16 quantity_carried = carried.getQuantity();
			const u16 request = item.maxQuantity - quantity_stored;

			if (request >= quantity_carried)
			{
				this.server_PutInInventory(carried);
			}
			else
			{
				item.server_SetQuantity(quantity_stored + request);
				carried.server_SetQuantity(quantity_carried - request);
			}
		}
	}
	else if (cmd == this.getCommandID("unload") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;
					
		CBlob@ caller = player.getBlob();
		if (caller is null) return;

		// range check
		if (this.getDistanceTo(caller) > 22.0f) return;

		if (caller is null) return;

		CBlob@ item = this.getInventory().getItem(0);
		if (item is null) return;

		caller.server_Pickup(item);
	}
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().SetFrameIndex(1);
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().SetFrameIndex(0);
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return false;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}
