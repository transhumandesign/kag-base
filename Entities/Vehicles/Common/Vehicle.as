#include "SeatsCommon.as"
#include "VehicleCommon.as"
#include "VehicleAttachmentCommon.as"

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
}

void onTick(CBlob@ this)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	// wheels
	if (this.getShape().vellen > 0.07f && !this.isAttached())
	{
		UpdateWheels(this);
	}

	// reload
	if (this.hasAttached() && getGameTime() % 2 == 0)
	{
		f32 time_til_fire = Maths::Max((v.fire_time - getGameTime()), 1);
		if (time_til_fire < 2)
		{
			Vehicle_LoadAmmoIfEmpty(this, v);
		}
	}

	// update movement sounds
	f32 velx = Maths::Abs(this.getVelocity().x);

	// ground sound

	if (velx < 0.02f || (!this.isOnGround() && !this.isInWater()))
	{
		CSprite@ sprite = this.getSprite();
		f32 vol = sprite.getEmitSoundVolume();
		sprite.SetEmitSoundVolume(vol * 0.9f);
		if (vol < 0.1f)
		{
			sprite.SetEmitSoundPaused(true);
			sprite.SetEmitSoundVolume(1.0f);
		}
	}
	else
	{
		if (this.isOnGround() && !v.ground_sound.isEmpty())
		{
			CSprite@ sprite = this.getSprite();
			if (sprite.getEmitSoundPaused())
			{
				this.getSprite().SetEmitSound(v.ground_sound);
				sprite.SetEmitSoundPaused(false);
			}

			f32 volMod = v.ground_volume;
			f32 pitchMod = v.ground_pitch;

			if (volMod > 0.0f)
			{
				sprite.SetEmitSoundVolume(Maths::Min(velx * 0.565f * volMod, 1.0f));
			}

			if (pitchMod > 0.0f)
			{
				sprite.SetEmitSoundSpeed(Maths::Max(Maths::Min(Maths::Sqrt(0.5f * velx * pitchMod), 1.5f), 0.75f));
			}
		}
		else if (!this.isOnGround() && !v.water_sound.isEmpty())
		{
			CSprite@ sprite = this.getSprite();
			if (sprite.getEmitSoundPaused())
			{
				this.getSprite().SetEmitSound(v.water_sound);
				sprite.SetEmitSoundPaused(false);
			}

			f32 volMod = v.water_volume;
			f32 pitchMod = v.water_pitch;

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
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();

	/// LOAD AMMO
	if (isServer && cmd == this.getCommandID("load_ammo"))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			// take all ammo blobs from caller and try to put in vehicle
			const string ammo = v.ammo_name;
			array < CBlob@ > ammos;

			CBlob@ carryObject = caller.getCarriedBlob();
			if (carryObject !is null && carryObject.getName() == ammo)
			{
				ammos.push_back(carryObject);
			}

			for (int i = 0; i < caller.getInventory().getItemsCount(); i++)
			{
				CBlob@ invItem = caller.getInventory().getItem(i);
				if (invItem.getName() == ammo)
				{
					ammos.push_back(invItem);
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
	}
	/// PUT IN MAG
	else if (isServer && cmd == this.getCommandID("putin_mag"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		CBlob@ blob = getBlobByNetworkID(params.read_u16());
		if (caller !is null && blob !is null)
		{
			// put what was in mag into inv
			CBlob@ magBlob = getMagBlob(this);
			if (magBlob !is null)
			{
				magBlob.server_DetachFromAll();
				this.server_PutInInventory(magBlob);
			}
			blob.server_DetachFromAll();
			this.server_AttachTo(blob, "MAG");
		}
	}
	/// FIRE
	else if (cmd == this.getCommandID("fire"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		const u8 charge = params.read_u8();
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Fire(this, v, caller, charge);
		if (isServer)
			RecountAmmo(this, v);
	}
	/// FLIP OVER
	else if (cmd == this.getCommandID("flip_over"))
	{
		if (isFlipped(this))
		{
			this.getShape().SetStatic(false);
			this.getShape().doTickScripts = true;
			f32 angle = this.getAngleDegrees();
			this.AddTorque(angle < 180 ? -1000 : 1000);
			this.AddForce(Vec2f(0, -1000));
		}
	}
	/// GET IN MAG
	else if (isServer && cmd == this.getCommandID("getin_mag"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
			this.server_AttachTo(caller, "MAG");
	}
	/// GET OUT
	else if (isServer && cmd == this.getCommandID("vehicle getout"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());

		if (caller !is null)
		{
			this.server_DetachFrom(caller);
		}
	}
	/// RELOAD as in server_LoadAmmo   - client-side
	else if (!isServer && cmd == this.getCommandID("reload"))
	{
		u8 loadedAmmo = params.read_u8();

		if (loadedAmmo > 0 && this.getAttachments() !is null)
		{
			SetOccupied(this.getAttachments().getAttachmentPointByName("MAG"), 1);
		}

		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		v.loaded_ammo = loadedAmmo;
	}
	else if (!isServer && cmd == this.getCommandID("recount ammo"))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		v.ammo_stocked = params.read_u16();
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	if (forBlob.getTeamNum() == this.getTeamNum())
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return false;
		}
		return v.inventoryAccess;
	}
	return false;
}

// VehicleCommon.as
void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 charge) {}
bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}
