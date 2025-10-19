#include "VehicleCommon.as"
#include "GenericButtonCommon.as"

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
}

void onTick(CBlob@ this)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	// reload
	if (this.hasAttached() && v.ammo_types.size() > 0)
	{
		const f32 time_til_fire = Maths::Max((v.fire_time - getGameTime()), 1);
		if (time_til_fire < 2)
		{
			Vehicle_LoadAmmoIfEmpty(this, v);
		}
	}
	CSprite@ sprite = this.getSprite();

	// wheels
	if (this.getShape().vellen > 0.07f && !this.isAttached() && !this.hasTag("immobile"))
	{
		UpdateWheels(sprite);
	}

	// movement sounds
	const f32 velx = Maths::Abs(this.getVelocity().x);
	if (velx < 0.02f || (!this.isOnGround() && !this.isInWater()))
	{
		const f32 vol = sprite.getEmitSoundVolume();
		sprite.SetEmitSoundVolume(vol * 0.9f);
		if (vol < 0.1f)
		{
			sprite.SetEmitSoundPaused(true);
			sprite.SetEmitSoundVolume(1.0f);
		}
	}
	else
	{
		string emitSound = "";
		f32 volMod = 0;
		f32 pitchMod = 0;
		if (this.isOnGround() && !v.ground_sound.isEmpty())
		{
			emitSound = v.ground_sound;
			volMod = v.ground_volume;
			pitchMod = v.ground_pitch;
		}
		else if (!this.isOnGround() && !v.water_sound.isEmpty())
		{
			emitSound = v.water_sound;
			volMod = v.water_volume;
			pitchMod =  v.water_pitch;
		}

		if (sprite.getEmitSoundPaused() && !emitSound.isEmpty())
		{
			sprite.SetEmitSound(emitSound);
			sprite.SetEmitSoundPaused(false);
		}

		if (volMod > 0.0f)
		{
			sprite.SetEmitSoundVolume(Maths::Min(velx * 0.565f * volMod, 1.0f));
		}

		if (pitchMod > 0.0f)
		{
			sprite.SetEmitSoundSpeed(Maths::Max(Maths::Min(Maths::Sqrt(0.5f * velx * pitchMod), 1.5f), 0.75f));
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	/// LOAD AMMO
	if (cmd == this.getCommandID("load_ammo") && isServer())
	{
		CPlayer@ callerp = getNet().getActiveCommandPlayer();
		if (callerp is null) return;

		CBlob@ caller = callerp.getBlob();
		if (caller is null) return;

		// range check
		if (this.getDistanceTo(caller) > this.getRadius()) return;

		// team check
		if (this.getTeamNum() != caller.getTeamNum()) return;

		CBlob@[] ammos;
		string[] eligible_ammo_names;

		for (int i = 0; i < v.ammo_types.length(); ++i)
		{
			eligible_ammo_names.push_back(v.ammo_types[i].ammo_name);
		}

		// if player has item in hand, we only put that item into vehicle's inventory
		CBlob@ carried = caller.getCarriedBlob();
		if (carried !is null && eligible_ammo_names.find(carried.getName()) != -1)
		{
			ammos.push_back(carried);
		}
		else
		{
			CInventory@ inv = caller.getInventory();
			for (int i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob@ item = inv.getItem(i);
				if (eligible_ammo_names.find(item.getName()) != -1)
				{
					ammos.push_back(item);
				}
			}
		}

		for (int i = 0; i < ammos.length; i++)
		{
			if (!this.server_PutInInventory(ammos[i]))
			{
				caller.server_PutInInventory(ammos[i]);
			}
		}

		RecountAmmo(this, v);
	}
	/// SWAP AMMO
	else if (cmd == this.getCommandID("swap_ammo") && isServer())
	{
		CPlayer@ p = getNet().getActiveCommandPlayer();
		if (p is null) return;

		CBlob@ b = p.getBlob();
		if (b is null) return;

		// don't swap ammo if only 1 ammo type
		if (v.ammo_types.size() <= 1) return;

		// don't swap ammo mid-charge
		if (v.charge > 0) return;

		// attached checks
		CAttachment@ ca = this.getAttachments();
		if (ca is null) return;
		AttachmentPoint@ ap = ca.getAttachmentPointByName("GUNNER");
		if (ap is null) return;
		CBlob@ attachedblob = ap.getOccupied();
		if (attachedblob is null) return;
		if (attachedblob !is b) return;

		u8 ammoIndex = v.current_ammo_index + 1;
		if (ammoIndex >= v.ammo_types.size())
		{
			ammoIndex = 0;
		}
		v.current_ammo_index = ammoIndex;

		this.SendCommand(this.getCommandID("swap_ammo_client"));
	}
	else if (cmd == this.getCommandID("swap_ammo_client") && isClient() && !isServer())
	{
		u8 ammoIndex = v.current_ammo_index + 1;
		if (ammoIndex >= v.ammo_types.size())
		{
			ammoIndex = 0;
		}
		v.current_ammo_index = ammoIndex;
	}
	/// FIRE
	else if (cmd == this.getCommandID("fire") && isServer())
	{
		CPlayer@ callerp = getNet().getActiveCommandPlayer();
		if (callerp is null) return;

		CBlob@ caller = callerp.getBlob();
		if (caller is null) return;

		CBitStream bt;
		bt.write_u16(caller.getNetworkID());
		bt.write_u16(v.charge);
		this.SendCommand(this.getCommandID("fire client"), bt);

		Fire(this, v, caller, v.charge);
	}
	else if (cmd == this.getCommandID("fire client") && isClient())
	{
		u16 id;
		if (!params.saferead_u16(id)) return;

		u16 charge;
		if (!params.saferead_u16(charge)) return;

		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		Fire(this, v, caller, charge);
	}
	/// POST FIRE
	else if (cmd == this.getCommandID("fire blob client") && isClient())
	{
		u16 id;
		if (!params.saferead_u16(id)) return;

		u16 charge;
		if (!params.saferead_u16(charge)) return;

		CBlob@ blob = getBlobByNetworkID(id);
		v.onFire(this, blob, charge);
	}
	/// FLIP OVER
	else if (cmd == this.getCommandID("flip_over") && isServer())
	{
		CPlayer@ p = getNet().getActiveCommandPlayer();
		if (p is null) return;

		CBlob@ b = p.getBlob();
		if (b is null) return;

		// range check
		if (this.getDistanceTo(b) > 64.0f) return;

		if (isFlipped(this))
		{
			this.getShape().SetStatic(false);
			this.getShape().doTickScripts = true;
			this.AddTorque(this.getAngleDegrees() < 180 ? -1000 : 1000);
			this.AddForce(Vec2f(0, -1000));
		}
	}
	/// SYNC AMMUNITION
	else if (cmd == this.getCommandID("recount ammo client") && isClient())
	{
		u8 current_recounted;
		if (!params.saferead_u8(current_recounted)) return;
		if (!params.saferead_u16(v.ammo_types[current_recounted].ammo_stocked)) return;
		if (!params.saferead_u8(v.ammo_types[current_recounted].loaded_ammo)) return;
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	if (forBlob.getTeamNum() == this.getTeamNum() && canSeeButtons(this, forBlob))
	{
		VehicleInfo@ v;
		if (this.get("VehicleInfo", @v))
		{
			return v.inventoryAccess;
		}
	}
	return false;
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	// reset charge if gunner leaves while charging
	if (attachedPoint.name == "GUNNER")
	{
		v.charge = 0;
	}

	// jump out
	if (detached.hasTag("player") && attachedPoint.socket)
	{
		detached.setPosition(detached.getPosition() + Vec2f(0.0f, -4.0f));
		detached.setVelocity(this.getVelocity() + v.out_vel);
		detached.IgnoreCollisionWhileOverlapped(null);
		this.IgnoreCollisionWhileOverlapped(null);
	}
}

///NETWORKING

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;
	stream.write_u8(v.current_ammo_index);
	stream.write_u8(v.last_fired_index);
	stream.write_f32(v.fly_amount);
	stream.write_u16(v.last_charge);
	for (int i = 0; i < v.ammo_types.size(); i++)
	{
		AmmoInfo@ ammo = v.ammo_types[i];
		stream.write_u8(ammo.loaded_ammo);
		stream.write_u16(ammo.ammo_stocked);
	}
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))                return true;
	if (!stream.saferead_u8(v.current_ammo_index))   return false;
	if (!stream.saferead_u8(v.last_fired_index))     return false;
	if (!stream.saferead_f32(v.fly_amount))          return false;
	if (!stream.saferead_u16(v.last_charge))         return false;
	for (int i = 0; i < v.ammo_types.size(); i++)
	{
		AmmoInfo@ ammo = v.ammo_types[i];
		if (!stream.saferead_u8(ammo.loaded_ammo))   return false;
		if (!stream.saferead_u16(ammo.ammo_stocked)) return false;
	}
	return true;
}
