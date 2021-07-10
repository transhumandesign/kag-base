#include "VehicleCommon.as"
#include "ClassSelectMenu.as";
#include "StandardRespawnCommand.as";
#include "GenericButtonCommon.as";
#include "Costs.as";

// Ballista logic

const u8 cooldown_time = 60;
const u8 cooldown_time_bomb = 90;

//naming here is kinda counter intuitive, but 0 == up, 90 == sideways
const f32 high_angle = 20.0f;
const f32 low_angle = 60.0f;

void onInit(CBlob@ this)
{
	this.Tag("respawn");

	InitRespawnCommand(this);
	InitClasses(this);
	this.Tag("change class drop inventory");

	InitCosts();
	this.set_s32("gold building amount", CTFCosts::ballista_gold);

	AddIconToken("$Normal_Bolt$", "BallistaBolt.png", Vec2f(32, 8), 0);
	AddIconToken("$Explosive_Bolt$", "BallistaBolt.png", Vec2f(32, 8), 1);

	Vehicle_Setup(this,
	              30.0f, // move speed
	              0.31f,  // turn speed
	              Vec2f(0.0f, 0.0f), // jump out velocity
	              false  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	//tech - bomb bolts
	//bool hasBomb = hasTech(this, "bomb ammo");
	//this.set_bool("bomb ammo", hasBomb);

	// bolt ammo
	Vehicle_AddAmmo(this, v,
	                    cooldown_time, // fire delay (ticks)
	                    1, // fire bullets amount
	                    1, // fire cost
	                    "mat_bolts", // bullet ammo config name
	                    "Ballista Bolts", // name for ammo selection
	                    "ballista_bolt", // bullet config name
	                    "CatapultFire", // fire sound
	                    "EmptyFire", // empty fire sound
	                    Vehicle_Fire_Style::custom,
	                    Vec2f(-6.0f, -8.0f), // fire position offset
	                    80 // charge time
	                   );

	// explosive bolt ammo
	Vehicle_AddAmmo(this, v,
	                    cooldown_time_bomb, // fire delay (ticks)
	                    1, // fire bullets amount
	                    1, // fire cost
	                    "mat_bomb_bolts", // bullet ammo config name
	                    "Ballista Shells", // name for ammo selection
	                    "ballista_bolt", // bullet config name
	                    "CatapultFire", // fire sound
	                    "EmptyFire", // empty fire sound
	                    Vehicle_Fire_Style::custom,
	                    Vec2f(-6.0f, -8.0f), // fire position offset
	                    80 // charge time
	                   );


	Vehicle_SetupGroundSound(this, v, "WoodenWheelsRolling",  // movement sound
	                         1.0f, // movement sound volume modifier   0.0f = no manipulation
	                         1.0f // movement sound pitch modifier     0.0f = no manipulation
	                        );

	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(10.0f, 18.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(-1.0f, 18.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(-11.0f, 18.0f)); if (w !is null) w.SetRelativeZ(10.0f); }

	this.getShape().SetOffset(Vec2f(0, 8));

	Vehicle_SetWeaponAngle(this, low_angle, v);

	string[] autograb_blobs = {"mat_bolts", "mat_bomb_bolts"};
	this.set("autograb blobs", autograb_blobs);

	// auto-load on creation
	if (getNet().isServer())
	{
		CBlob@ ammo = server_CreateBlob("mat_bolts");
		if (ammo !is null)
		{
			if (!this.server_PutInInventory(ammo))
				ammo.server_Die();
		}
	}

	// init arm sprites
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 24, 40);

	if (arm !is null)
	{
		f32 angle = low_angle;

		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(10);

		CSpriteLayer@ arm = this.getSprite().getSpriteLayer("arm");
		if (arm !is null)
		{
			arm.SetRelativeZ(0.5f);
			arm.RotateBy(angle, Vec2f(-0.5f, 15.5f));
			arm.SetOffset(Vec2f(10.0f, -6.0f));
		}
	}

	sprite.SetZ(-25.0f);
	CSpriteLayer@ front = sprite.addSpriteLayer("front layer", sprite.getConsts().filename, 40, 40);
	if (front !is null)
	{
		front.addAnimation("default", 0, false);
		int[] frames = { 0, 1, 2 };
		front.animation.AddFrames(frames);
		front.SetRelativeZ(0.8f);
	}

	CSpriteLayer@ flag = sprite.addSpriteLayer("flag layer", sprite.getConsts().filename, 32, 32);
	if (flag !is null)
	{
		flag.addAnimation("default", 3, true);
		int[] frames = { 15, 14, 13 };
		flag.animation.AddFrames(frames);
		flag.SetRelativeZ(-0.8f);
		flag.SetOffset(Vec2f(20.0f, -2.0f));
	}
}

f32 getAngle(CBlob@ this, const u8 charge, VehicleInfo@ v)
{
	f32 angle = 180.0f; //we'll know if this goes wrong :)
	bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");

	bool not_found = true;

	if (gunner !is null && gunner.getOccupied() !is null)
	{
		Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos();

		if ((!facing_left && aim_vec.x < 0) ||
		        (facing_left && aim_vec.x > 0))
		{
			if (aim_vec.x > 0) { aim_vec.x = -aim_vec.x; }
			aim_vec.RotateBy((facing_left ? 1 : -1) * this.getAngleDegrees());

			angle = (-(aim_vec).getAngle() + 270.0f);
			angle = Maths::Max(high_angle , Maths::Min(angle , low_angle));
			//printf("angle " + angle );
			not_found = false;
		}
	}

	if (not_found)
	{
		angle = Maths::Abs(Vehicle_getWeaponAngle(this, v));
		return (facing_left ? -angle : angle);
	}

	if (facing_left) { angle *= -1; }

	return angle;
}

void onTick(CBlob@ this)
{
	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Vehicle_StandardControls(this, v);

		if (v.cooldown_time > 0)
		{
			v.cooldown_time--;
		}

		f32 angle = getAngle(this, v.charge, v);
		Vehicle_SetWeaponAngle(this, angle, v);

		CSprite@ sprite = this.getSprite();

		CSpriteLayer@ arm = sprite.getSpriteLayer("arm");
		if (arm !is null)
		{
			arm.ResetTransform();
			f32 floattime = getGameTime();
			arm.RotateBy(angle, Vec2f(-0.5f, 15.5f));
			arm.SetOffset(Vec2f(10.0f, -6.0f));

			/*if (this.get_u8("loaded ammo") > 0) {
				arm.animation.frame = 1;
			}
			else {
				arm.animation.frame = 0;
			}*/
		}

		if (getNet().isClient())
		{
			CPlayer@ p = getLocalPlayer();
			if (p !is null)
			{
				CBlob@ local = p.getBlob();
				if (local !is null)
				{
					CSpriteLayer@ front = sprite.getSpriteLayer("front layer");
					if (front !is null)
					{
						front.SetVisible(!local.isAttachedTo(this));
					}
				}
			}
		}
	}

}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (isOverlapping(this, caller) && !caller.isAttached())
	{
		if (!Vehicle_AddFlipButton(this, caller) && caller.getTeamNum() == this.getTeamNum())
		{
			Vehicle_AddLoadAmmoButton(this, caller);
		}
		if (!isAnotherRespawnClose(this) && !isFlipped(this))
		{
			caller.CreateGenericButton("$change_class$", Vec2f(0, 1), this, buildSpawnMenu, getTranslatedString("Change class"));
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == SpawnCmd::changeClass)
	{
		onRespawnCommand(this, cmd, params);
	}
	else if (cmd == this.getCommandID("fire blob"))
	{
		CBlob@ blob = getBlobByNetworkID(params.read_netid());
		const u8 charge = params.read_u8();
		
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		
		// check for valid ammo
		if (blob.getName() != v.getCurrentAmmo().bullet_name){
			// output warning
			warn("Attempted to launch invalid object!");
			return;
		}
		
		Vehicle_onFire(this, v, blob, charge);
	}
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue)
{
	v.firing = v.firing || isActionPressed;

	bool hasammo = v.getCurrentAmmo().loaded_ammo > 0;

	u8 charge = v.charge;
	if ((charge > 0 || isActionPressed) && hasammo)
	{
		if (charge < v.getCurrentAmmo().max_charge_time && isActionPressed)
		{
			charge++;
			v.charge = charge;

			u8 t = Maths::Round(float(v.getCurrentAmmo().max_charge_time) * 0.66f);
			if ((charge < t && charge % 10 == 0) || (charge >= t && charge % 5 == 0))
				this.getSprite().PlaySound("/LoadingTick");

			chargeValue = charge;
			return false;
		}
		chargeValue = charge;
		return true;
	}

	return false;
}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge)
{
	u16 delay = cooldown_time;

	if (bullet !is null)
	{
		u8 charge_prop = _charge;

		f32 charge = 5.0f + 15.0f * (float(charge_prop) / float(v.getCurrentAmmo().max_charge_time));

		f32 angle = getAngle(this, _charge, v) + this.getAngleDegrees();
		Vec2f vel = Vec2f(0.0f, -charge).RotateBy(angle);
		bullet.setVelocity(vel);
		bullet.setPosition(bullet.getPosition() + vel);

		bool bomb_bolts_selected = v.getCurrentAmmo().ammo_name == "mat_bomb_bolts";

		if (bomb_bolts_selected)
		{
			delay = cooldown_time_bomb;
			bullet.Tag("bomb ammo");
			bullet.Sync("bomb ammo", true);
		}
	}

	v.last_charge = _charge;
	v.charge = 0;
	v.cooldown_time = delay;
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
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	attachedPoint.offsetZ = 1.0f;
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

bool isAnotherRespawnClose(CBlob@ this)
{
	CBlob@[] blobsInRadius;
	if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() * 1.5f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b !is this && b.hasTag("respawn") && b.getNetworkID() < this.getNetworkID())
			{
				return true;
			}
		}
	}
	return false;
}

// Blame Fuzzle.
bool isOverlapping(CBlob@ this, CBlob@ blob)
{

	Vec2f tl, br, _tl, _br;
	this.getShape().getBoundingRect(tl, br);
	blob.getShape().getBoundingRect(_tl, _br);
	return br.x > _tl.x
	       && br.y > _tl.y
	       && _br.x > tl.x
	       && _br.y > tl.y;

}
