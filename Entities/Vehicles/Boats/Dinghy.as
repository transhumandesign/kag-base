#include "VehicleCommon.as"
#include "GenericButtonCommon.as"

// Boat logic

void onInit(CBlob@ this)
{
	this.addCommandID("store inventory");
	AddIconToken("$store_inventory$", "InteractionIcons.png", Vec2f(32, 32), 28);

	Vehicle_Setup(this,
	              240.0f, // move speed
	              0.31f,  // turn speed
	              Vec2f(0.0f, -2.5f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	Vehicle_SetupWaterSound(this, v, "BoatRowing",  // movement sound
	                        0.0f, // movement sound volume modifier   0.0f = no manipulation
	                        0.0f // movement sound pitch modifier     0.0f = no manipulation
	                       );
	this.getShape().SetCenterOfMassOffset(Vec2f(-1.5f, 4.5f));
	this.getShape().getConsts().transports = true;
	this.Tag("medium weight");
	this.set_u16("capture time", 10); // captures quicker

	// add custom capture zone
	getMap().server_AddMovingSector(Vec2f(-12.0f, -12.0f), Vec2f(12.0f, 0.0f), "capture zone "+this.getNetworkID(), this.getNetworkID());
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (caller.getTeamNum() == this.getTeamNum())
	{
		CInventory@ inv = caller.getInventory();
		if (inv is null) return;

		if (inv.getItemsCount() > 0)
		{
			caller.CreateGenericButton("$store_inventory$", Vec2f(0, 10), this, this.getCommandID("store inventory"), getTranslatedString("Store"));
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("store inventory") && isServer())
	{
		CPlayer@ p = getNet().getActiveCommandPlayer();
		if (p is null) return;
					
		CBlob@ caller = p.getBlob();
		if (caller is null) return;

		// range check; same as default cbutton range in engine (8 blocks)...
		if (this.getDistanceTo(caller) > 64.0f) return;

		CBlob@ carried = caller.getCarriedBlob();
		if (carried !is null && carried.hasTag("temp blob"))
		{
			carried.server_Die();
		}

		CInventory@ inv = caller.getInventory();
		if (inv !is null)
		{
			while (inv.getItemsCount() > 0)
			{
				CBlob@ item = inv.getItem(0);
				caller.server_PutOutInventory(item);
				this.server_PutInInventory(item);
			}
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.hasAttached() && !this.isInWater() &&
	       this.getOldVelocity().LengthSquared() < 4.0f &&
	       this.getTeamNum() == byBlob.getTeamNum();
}

void onTick(CBlob@ this)
{
	if (this.hasAttached())
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v)) return;

		Vehicle_StandardControls(this, v);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return Vehicle_doesCollideWithBlob_boat(this, blob);
}
