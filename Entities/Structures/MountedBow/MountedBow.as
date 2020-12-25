#include "VehicleCommon.as"
#include "GenericButtonCommon.as"

// Mounted Bow logic

const Vec2f arm_offset = Vec2f(-6, 0);

void onInit(CBlob@ this)
{
	Vehicle_Setup(this,
	              0.0f, // move speed
	              0.31f,  // turn speed
	              Vec2f(0.0f, 0.0f), // jump out velocity
	              false  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_SetupWeapon(this, v,
	                    25, // fire delay (ticks)
	                    1, // fire bullets amount
	                    Vec2f(-6.0f, 2.0f), // fire position offset
	                    "mat_arrows", // bullet ammo config name
	                    "arrow", // bullet config name
	                    "BowFire", // fire sound
	                    "EmptyFire" // empty fire sound
	                   );
	v.charge = 400;
	// init arm + cage sprites
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 16, 16);

	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(4);
		anim.AddFrame(5);
		arm.SetOffset(arm_offset);
	}

	CSpriteLayer@ cage = sprite.addSpriteLayer("cage", sprite.getConsts().filename, 8, 16);

	if (cage !is null)
	{
		Animation@ anim = cage.addAnimation("default", 0, false);
		anim.AddFrame(1);
		anim.AddFrame(5);
		anim.AddFrame(7);
		cage.SetOffset(sprite.getOffset());
		cage.SetRelativeZ(20.0f);
	}

	this.getShape().SetRotationsAllowed(false);
	this.set_string("autograb blob", "mat_arrows");

	sprite.SetZ(-10.0f);

	this.getCurrentScript().runFlags |= Script::tick_hasattached;

	// auto-load on creation
	if (getNet().isServer())
	{
		CBlob@ ammo = server_CreateBlob("mat_arrows");
		if (ammo !is null)
		{
			if (!this.server_PutInInventory(ammo))
				ammo.server_Die();
		}
	}
}

f32 getAimAngle(CBlob@ this, VehicleInfo@ v)
{
	f32 angle = Vehicle_getWeaponAngle(this, v);
	bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
	bool failed = true;

	if (gunner !is null && gunner.getOccupied() !is null)
	{
		gunner.offsetZ = 5.0f;
		Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos();

		if (this.isAttached())
		{
			if (facing_left) { aim_vec.x = -aim_vec.x; }
			angle = (-(aim_vec).getAngle() + 180.0f);
		}
		else
		{
			if ((!facing_left && aim_vec.x < 0) ||
			        (facing_left && aim_vec.x > 0))
			{
				if (aim_vec.x > 0) { aim_vec.x = -aim_vec.x; }

				angle = (-(aim_vec).getAngle() + 180.0f);
				angle = Maths::Max(-80.0f , Maths::Min(angle , 80.0f));
			}
			else
			{
				this.SetFacingLeft(!facing_left);
			}
		}
	}

	return angle;
}

void onTick(CBlob@ this)
{
	if (this.hasAttached() || this.getTickSinceCreated() < 30) //driver, seat or gunner, or just created
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		//set the arm angle based on GUNNER mouse aim, see above ^^^^
		f32 angle = getAimAngle(this, v);
		Vehicle_SetWeaponAngle(this, angle, v);
		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ arm = sprite.getSpriteLayer("arm");

		if (arm !is null)
		{
			bool facing_left = sprite.isFacingLeft();
			f32 rotation = angle * (facing_left ? -1 : 1);

			if (v.loaded_ammo > 0)
			{
				arm.animation.frame = 1;
			}
			else
			{
				arm.animation.frame = 0;
			}

			arm.ResetTransform();
			arm.SetFacingLeft(facing_left);
			arm.SetRelativeZ(1.0f);
			arm.SetOffset(arm_offset);
			arm.RotateBy(rotation, Vec2f(facing_left ? -4.0f : 4.0f, 0.0f));
		}


		Vehicle_StandardControls(this, v);
	}
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{

	f32 hp = this.getHealth();
	f32 max_hp = this.getInitialHealth();
	int damframe = hp < max_hp * 0.4f ? 2 : hp < max_hp * 0.9f ? 1 : 0;
	CSprite@ sprite = this.getSprite();
	sprite.animation.frame = damframe;
	CSpriteLayer@ cage = sprite.getSpriteLayer("cage");
	if (cage !is null)
	{
		cage.animation.frame = damframe;
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (!Vehicle_AddFlipButton(this, caller))
	{
		Vehicle_AddLoadAmmoButton(this, caller);
	}
}


bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _unused)
{
	if (bullet !is null)
	{
		u16 charge = v.charge;
		f32 angle = Vehicle_getWeaponAngle(this, v);
		angle = angle * (this.isFacingLeft() ? -1 : 1);
		angle += ((XORRandom(512) - 256) / 64.0f);

		Vec2f vel = Vec2f(charge / 16.0f * (this.isFacingLeft() ? -1 : 1), 0.0f).RotateBy(angle);
		bullet.setVelocity(vel);
		Vec2f offset = arm_offset;

		//(handle facing correctly)
		offset.x *= (this.isFacingLeft() ? 1 : -1);
		offset.RotateBy(angle);
		offset.Normalize();
		//offset set length from shoot pos
		offset *= 3.5f;
		bullet.setPosition(this.getPosition() + offset);

		// set much higher drag than archer arrow
		bullet.getShape().setDrag(bullet.getShape().getDrag() * 2.0f);

		bullet.server_SetTimeToDie(-1);   // override lock
		bullet.server_SetTimeToDie(0.69f);
		bullet.Tag("bow arrow");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("fire blob"))
	{
		CBlob@ blob = getBlobByNetworkID(params.read_netid());
		const u8 charge = params.read_u8();
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Vehicle_onFire(this, v, blob, charge);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		TryToAttachVehicle(this, blob);
	}
}
