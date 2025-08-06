#include "VehicleCommon.as"
#include "GenericButtonCommon.as"

// Mounted Bow logic

class MountedBowInfo : VehicleInfo
{
	void onFire(CBlob@ this, CBlob@ bullet, const u16 &in fired_charge)
	{
		if (bullet !is null)
		{
			const f32 sign = this.isFacingLeft() ? -1 : 1;
			f32 angle = wep_angle * sign;
			angle += (XORRandom(512) - 256) / 64.0f;

			const f32 arrow_speed = 25.0f;
			Vec2f vel = Vec2f(arrow_speed * sign, 0.0f).RotateBy(angle);
			bullet.setVelocity(vel);

			// set much higher drag than archer arrow
			bullet.getShape().setDrag(bullet.getShape().getDrag() * 2.0f);
			bullet.Tag("bow arrow");
		}
	}
}

void onInit(CBlob@ this)
{
	this.Tag("medium weight");

	Vehicle_Setup(this,
	              0.0f, // move speed
	              0.31f,  // turn speed
	              Vec2f(0.0f, 0.0f), // jump out velocity
	              false,  // inventory access
	              MountedBowInfo()
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	Vehicle_AddAmmo(this, v,
	                    35, // fire delay (ticks)
	                    1, // fire bullets amount
	                    1, // fire cost
	                    "mat_arrows", // bullet ammo config name
	                    "Arrows", // name for ammo selection
	                    "arrow", // bullet config name
	                    "BowFire", // fire sound
	                    "EmptyFire", // empty fire sound
	                    Vec2f(-3, 0) //fire position offset
	                   );

	// init arm + cage sprites
	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-10.0f);
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 16, 16);
	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		int[] frames = { 4, 5 };
		anim.AddFrames(frames);
		arm.SetOffset(Vec2f(-6, 0));
		arm.SetRelativeZ(1.0f);
	}

	CSpriteLayer@ cage = sprite.addSpriteLayer("cage", sprite.getConsts().filename, 8, 16);
	if (cage !is null)
	{
		Animation@ anim = cage.addAnimation("default", 0, false);
		int[] frames = { 1, 5, 7 };
		anim.AddFrames(frames);
		cage.SetOffset(sprite.getOffset());
		cage.SetRelativeZ(20.0f);
	}

	UpdateFrame(this);

	this.getShape().SetRotationsAllowed(false);

	string[] autograb_blobs = {"mat_arrows"};
	this.set("autograb blobs", autograb_blobs);

	this.set_bool("facing", true);

	// auto-load on creation
	if (isServer())
	{
		CBlob@ ammo = server_CreateBlob("mat_arrows");
		if (ammo !is null && !this.server_PutInInventory(ammo))
		{
			ammo.server_Die();
		}
	}

	CMap@ map = getMap();
	if (map is null) return;

	this.SetFacingLeft(this.getPosition().x > (map.tilemapwidth * map.tilesize) / 2);
}

f32 getAimAngle(CBlob@ this, VehicleInfo@ v)
{
	f32 angle = v.wep_angle;
	const bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
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
	if (this.hasAttached() || this.get_bool("facing") != this.isFacingLeft())
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v)) return;

		const f32 angle = getAimAngle(this, v);
		v.wep_angle = angle;

		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ arm = sprite.getSpriteLayer("arm");
		if (arm !is null)
		{
			const f32 sign = sprite.isFacingLeft() ? -1 : 1;
			const f32 rotation = angle * sign;

			arm.ResetTransform();
			arm.RotateBy(rotation, Vec2f(4.0f * sign, 0.0f));
			arm.animation.frame = v.getCurrentAmmo().loaded_ammo > 0 ? 1 : 0;
		}

		Vehicle_StandardControls(this, v);
	}
	this.set_bool("facing", this.isFacingLeft());
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	UpdateFrame(this);
}

void UpdateFrame(CBlob@ this)
{
	CSpriteLayer@ cage = this.getSprite().getSpriteLayer("cage");
	if (cage !is null)
	{
		cage.animation.setFrameFromRatio(1.0f - this.getHealth() / this.getInitialHealth());
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

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		TryToAttachVehicle(this, blob);
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	if (this.isAttached() || this.hasAttached() ||this.hasTag("unpickable"))	{ return false; }
	
	return (this.getTeamNum() == byBlob.getTeamNum() || this.isOverlapping(byBlob));
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
    return blob.getShape().isStatic();
}
