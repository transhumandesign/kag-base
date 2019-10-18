#include "VehicleCommon.as"
#include "GenericButtonCommon.as"

// Boat logic

void onInit(CBlob@ this)
{
	this.addCommandID("store inventory");

	AddIconToken("$store_inventory$", "InteractionIcons.png", Vec2f(32, 32), 28);

	Vehicle_Setup(this,
	              200.0f, // move speed
	              0.31f,  // turn speed
	              Vec2f(0.0f, -2.5f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_SetupWaterSound(this, v, "BoatRowing",  // movement sound
	                        0.0f, // movement sound volume modifier   0.0f = no manipulation
	                        0.0f // movement sound pitch modifier     0.0f = no manipulation
	                       );
	this.getShape().SetOffset(Vec2f(0, 9));
	this.getShape().SetCenterOfMassOffset(Vec2f(-1.5f, 4.5f));
	this.getShape().getConsts().transports = true;
	this.Tag("medium weight");
	this.Tag("short raid time"); // captures quicker
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (caller.getTeamNum() == this.getTeamNum())
	{
		CInventory @inv = caller.getInventory();
		if (inv is null) return;

		if (inv.getItemsCount() > 0)
		{
			CBitStream params;
			params.write_u16(caller.getNetworkID());
			caller.CreateGenericButton("$store_inventory$", Vec2f(0, 10), this, this.getCommandID("store inventory"), getTranslatedString("Store"), params);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (getNet().isServer())
	{
		if (cmd == this.getCommandID("store inventory"))
		{
			CBlob@ caller = getBlobByNetworkID(params.read_u16());
			if (caller !is null)
			{
				CInventory @inv = caller.getInventory();
				if (caller.getConfig() == "builder")
				{
					CBlob@ carried = caller.getCarriedBlob();
					if (carried !is null)
					{
						// TODO: find a better way to check and clear blocks + blob blocks || fix the fundamental problem, blob blocks not double checking requirement prior to placement.
						if (carried.hasTag("temp blob"))
						{
							carried.server_Die();
						}
					}
				}
				if (inv !is null)
				{
					while (inv.getItemsCount() > 0)
					{
						CBlob @item = inv.getItem(0);
						caller.server_PutOutInventory(item);
						this.server_PutInInventory(item);
					}
				}
			}
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.hasAttached() &&
	       (!this.isInWater() || this.isOnMap()) &&
	       this.getOldVelocity().LengthSquared() < 4.0f &&
		   this.getTeamNum() == byBlob.getTeamNum();
}

void onTick(CBlob@ this)
{
	const int time = this.getTickSinceCreated();
	if (this.hasAttached() || time < 30) //driver, seat or gunner, or just created
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Vehicle_StandardControls(this, v);
	}
}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 charge) {}
bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return Vehicle_doesCollideWithBlob_boat(this, blob);
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_onAttach(this, v, attached, attachedPoint);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_onDetach(this, v, detached, attachedPoint);
}
