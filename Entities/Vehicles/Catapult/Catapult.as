#include "VehicleCommon.as"
#include "KnockedCommon.as";
#include "GenericButtonCommon.as";

// Catapult logic

const u8 cooldown_time_ammo = 45;
const u8 cooldown_time_player = 91;
const u8 startStone = 100;

class CatapultInfo : VehicleInfo
{
	Random _r(0xca7a);
	u8 baseline_charge = 15;

	bool canFire(CBlob@ this, AttachmentPoint@ ap)
	{
		if (ap.isKeyPressed(key_action2))
		{
			//cancel
			charge = 0;
			cooldown_time = Maths::Max(cooldown_time, 15);
			return false;
		}

		if (cooldown_time > 0)
		{
			return false;
		}

		const bool isActionPressed = ap.isKeyPressed(key_action1);
		if (charge > 0 || isActionPressed)
		{
			if (charge < getCurrentAmmo().max_charge_time && isActionPressed)
			{
				charge++;

				const u8 t = Maths::Round(f32(getCurrentAmmo().max_charge_time) * 0.66f);
				if ((charge < t && charge % 10 == 0) || (charge >= t && charge % 5 == 0))
					this.getSprite().PlaySound("/LoadingTick");
				return false;
			}

			if (charge < baseline_charge)
				return false;

			CBlob@ occupied = this.getAttachments().getAttachmentPoint("MAG").getOccupied();
			CBlob@ caller = ap.getOccupied();
			if (occupied !is null && caller !is null)
			{
				if (isServer())
				{
					this.server_DetachFrom(occupied); //detach before sending the command to avoid velocity issues
					CBitStream params;
					params.write_netid(caller.getNetworkID());
					params.write_netid(occupied.getNetworkID());
					params.write_u8(charge);
					this.SendCommand(this.getCommandID("fire mag blob"), params);
				}
				return false;
			}
			return true;
		}
		return false;
	}

	void onFire(CBlob@ this, CBlob@ bullet, const u16 &in fired_charge)
	{
		const u8 charge_contrib = 35;
		const f32 temp_charge = baseline_charge + (f32(fired_charge) / f32(getCurrentAmmo().max_charge_time)) * charge_contrib;

		// we override the default time because we want to base it on charge
		int delay = 30 + (temp_charge / (250 / 30));

		if (bullet !is null)
		{
			const f32 player_launch_modifier = 0.75f;
			const f32 other_launch_modifier = 1.1f;

			const f32 sign = this.isFacingLeft() ? -1.0f : 1.0f;
			Vec2f vel = Vec2f(sign, -0.5f) * temp_charge * 0.3f;
			vel += (Vec2f((_r.NextFloat() - 0.5f) * 128, (_r.NextFloat() - 0.5f) * 128) * 0.01f);
			vel.RotateBy(this.getAngleDegrees());

			if (bullet.hasTag("player"))
			{
				delay *= f32(cooldown_time_player) / cooldown_time_ammo;
				bullet.setVelocity(vel * player_launch_modifier);
			}
			else
			{
				bullet.setVelocity(vel * other_launch_modifier);
			}

			if (isKnockable(bullet)) //causes an error on reload
			{
				setKnocked(bullet, 30);
			}

			if (bullet.getName() == "boulder") // rock n' roll baby
			{
				bullet.getShape().getConsts().mapCollisions = false;
				bullet.getShape().getConsts().collidable = false;
			}
		}

		last_charge = fired_charge;
		charge = 0;
		getCurrentAmmo().fire_delay = delay;
		cooldown_time = delay;
	}
}

void onInit(CBlob@ this)
{
	Vehicle_Setup(this,
	              30.0f, // move speed
	              0.31f,  // turn speed
	              Vec2f(0.0f, 0.0f), // jump out velocity
	              false,  // inventory access
	              CatapultInfo()
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	Vehicle_AddAmmo(this, v,
	                    cooldown_time_ammo, // fire delay (ticks)
	                    7, // fire bullets amount
	                    3, // fire cost
	                    "mat_stone", // bullet ammo config name
	                    "Catapult Rocks", // name for ammo selection
	                    "cata_rock", // bullet config name
	                    "CatapultFire", // fire sound
	                    "CatapultFire", // empty fire sound
	                    Vec2f(0, -16), //fire position offset
	                    90 // charge time
	);

	Vehicle_SetupGroundSound(this, v, "WoodenWheelsRolling",  // movement sound
	                         1.0f, // movement sound volume modifier   0.0f = no manipulation
	                         1.0f // movement sound pitch modifier     0.0f = no manipulation
	                        );
	Vehicle_addWheel(this, v, "WoodenWheels.png", 16, 16, 1, Vec2f(-10.0f, 11.0f));
	Vehicle_addWheel(this, v, "WoodenWheels.png", 16, 16, 0, Vec2f(8.0f, 10.0f));

	this.getShape().SetOffset(Vec2f(0, 6));
	
	this.addCommandID("putin_mag");
	this.addCommandID("fire mag blob");

	string[] autograb_blobs = {"mat_stone"};
	this.set("autograb blobs", autograb_blobs);

	this.set_bool("facing", false);

	// auto-load on creation
	if (isServer())
	{
		CBlob@ ammo = server_CreateBlob("mat_stone");
		if (ammo !is null)
		{
			ammo.server_SetQuantity(startStone);
			if (!this.server_PutInInventory(ammo))
				ammo.server_Die();
		}
	}
}

void onTick(CBlob@ this)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	AmmoInfo@ ammo = v.getCurrentAmmo();
	const f32 time_til_fire = Maths::Max(0, Maths::Min(v.fire_time - getGameTime(), ammo.fire_delay));
	if (this.hasAttached() || this.get_bool("hadattached") || this.get_bool("facing") != this.isFacingLeft() || time_til_fire > 0)
	{
		Vehicle_StandardControls(this, v);

		if (v.cooldown_time > 0)
		{
			v.cooldown_time--;
		}

		if (isClient()) //only matters visually on client
		{
			CSpriteLayer@ arm = this.getSprite().getSpriteLayer("arm");
			if (arm !is null)
			{
				//set the arm angle based on how long ago we fired
				const f32 rechargeRatio = time_til_fire / ammo.fire_delay;
				const f32 angle = 360.0f * (1.0f - rechargeRatio);
				const f32 armAngle = 20 + (angle / 9) + (f32(v.charge) / f32(ammo.max_charge_time)) * 20;

				Vec2f armOffset = Vec2f(-12.0f, -10.0f);
				arm.SetOffset(armOffset);

				arm.ResetTransform();
				arm.SetRelativeZ(-10.5f);
				arm.RotateBy(armAngle * (this.isFacingLeft() ? 1 : -1), Vec2f(0.0f, 13.0f));

				AttachmentPoint@ mag = this.getAttachments().getAttachmentPoint("MAG");
				arm.animation.frame = mag.getOccupied() is null && ammo.loaded_ammo > 0 ? 1 : 0;
				
				// set the bowl attachment offset
				Vec2f offset = Vec2f(4, -10);
				offset.RotateBy(-armAngle, Vec2f(0.0f, 13.0f));
				offset += armOffset + Vec2f(28, 0);
				mag.offset = offset;
			}
		}
	}
	this.set_bool("facing", this.isFacingLeft());
	this.set_bool("hadattached", this.hasAttached());
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	AttachmentPoint@ mag = this.getAttachments().getAttachmentPoint("MAG");
	CBlob@ occupied = mag.getOccupied();
	if (!Vehicle_AddFlipButton(this, caller) &&
	    this.getTeamNum() == caller.getTeamNum() &&
	    this.getDistanceTo(caller) < this.getRadius() &&
	    !caller.isAttached() &&
	    (occupied is null || !occupied.hasTag("player")))
	{
		// put in what is carried into mag
		CBlob@ carried = caller.getCarriedBlob();
		if (carried !is null && !carried.hasTag("temp blob"))
		{
			CBitStream callerParams;
			callerParams.write_netid(caller.getNetworkID());
			callerParams.write_netid(carried.getNetworkID());

			string name = carried.getInventoryName();
			const string msg = getTranslatedString("Load {ITEM}").replace("{ITEM}", name);

			string iconName = "$" + carried.getName() + "$"; 
			if (GUI::hasIconName("$" + carried.getInventoryName() + "$"))
			{
				iconName = "$" + carried.getInventoryName() + "$";
			}

			caller.CreateGenericButton(iconName, mag.offset, this, this.getCommandID("putin_mag"), msg, callerParams);
			return;
		}

		//otherwise load in ammo
		Vehicle_AddLoadAmmoButton(this, caller, mag.offset);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;
	
	if (cmd == this.getCommandID("fire"))
	{
		v.charge = 0; //for empty shots
	}
	else if (cmd == this.getCommandID("fire mag blob"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		CBlob@ occupied = getBlobByNetworkID(params.read_netid());
		const u8 charge = params.read_u8();

		if (caller !is null && occupied !is null && !occupied.hasTag("player"))
			occupied.SetDamageOwnerPlayer(caller.getPlayer());

		this.getSprite().PlayRandomSound(v.getCurrentAmmo().fire_sound);
		v.onFire(this, occupied, charge);
		v.SetFireDelay(v.getCurrentAmmo().fire_delay);
	}
	else if (isServer() && cmd == this.getCommandID("putin_mag"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		CBlob@ blob = getBlobByNetworkID(params.read_netid());
		if (caller !is null && blob !is null && blob.isAttachedTo(caller))
		{
			CBlob@ occupied = this.getAttachments().getAttachmentPoint("MAG").getOccupied();
			if (occupied !is null)
			{
				occupied.server_DetachFromAll();
			}
			blob.server_DetachFromAll();
			this.server_AttachTo(blob, "MAG");
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return Vehicle_doesCollideWithBlob_ground(this, blob);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		TryToAttachVehicle(this, blob);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;
	
	if (isServer() && attached.getName() == v.getCurrentAmmo().ammo_name)
	{
		// put stone material in inventory
		attached.server_DetachFromAll();
		this.server_PutInInventory(attached);
		server_LoadAmmo(this, attached, v.getCurrentAmmo().fire_amount, v);
	}
}
