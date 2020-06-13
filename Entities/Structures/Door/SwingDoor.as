// Swing Door logic

#include "Hitters.as"
#include "FireCommon.as"
#include "MapFlags.as"
#include "DoorCommon.as"

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(false);

	this.set_s16(burn_duration , 300);
	//transfer fire to underlying tiles
	this.Tag(spread_fire_tag);

	// this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().tickFrequency = 0;

	//block knight sword
	this.Tag("blocks sword");

	// disgusting HACK
	// for DefaultNoBuild.as
	if (this.getName() == "stone_door")
	{
		this.set_TileType("background tile", CMap::tile_castle_back);

		if (getNet().isServer())
		{
			dictionary harvest;
			harvest.set('mat_stone', 10);
			this.set('harvest', harvest);
		}
	}
	else
	{
		this.set_TileType("background tile", CMap::tile_wood_back);

		if (getNet().isServer())
		{
			dictionary harvest;
			harvest.set('mat_wood', 10);
			this.set('harvest', harvest);
		}
	}

	this.set_string("close_anim", "close");

	this.Tag("door");
	this.Tag("blocks water");
	this.Tag("explosion always teamkill"); // ignore 'no teamkill' for explosives

	this.getShape().getConsts().collidable = false;

}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;

	this.getSprite().PlaySound("/build_door.ogg");

	// open if door is built into something else
	CMap@ map = getMap();
	if (map !is null)
	{
		Vec2f pos = this.getPosition();
		CBlob@[] overlapping;
		map.getBlobsInBox(pos, pos, @overlapping);
		for (uint i = 0; i < overlapping.length; i++)
		{
			CBlob@ blob = overlapping[i];
			print("overlapping blob: " + blob.getName());
			string bname = blob.getName();
			if (blob !is null
				&& !blob.getShape().isStatic()
				&& blob.isCollidable()
				&& bname != "wooden_door" && bname != "stone_door")
			{
				setOpen(this, true, true);
				return;
			}

		}

	}

	this.getShape().getConsts().collidable = true;
}

//TODO: fix flags sync and hitting
/*void onDie(CBlob@ this)
{
    SetSolidFlag(this, false);
}*/

bool isOpen(CBlob@ this)
{
	return !this.getShape().getConsts().collidable;
}

void setOpen(CBlob@ this, bool open, bool faceLeft = false)
{
	CSprite@ sprite = this.getSprite();
	if (open)
	{
		sprite.SetZ(-100.0f);
		sprite.SetAnimation("open");
		this.getShape().getConsts().collidable = false;
		this.getCurrentScript().tickFrequency = 3;
		sprite.SetFacingLeft(faceLeft);   // swing left or right
		Sound::Play("/DoorOpen.ogg", this.getPosition());
	}
	else
	{
		sprite.SetZ(100.0f);
		sprite.SetAnimation(this.get_string("close_anim"));
		this.getShape().getConsts().collidable = true;
		this.getCurrentScript().tickFrequency = 0;
		Sound::Play("/DoorClose.ogg", this.getPosition());

		faceLeft = sprite.isFacingLeft();
		Vec2f pos = this.getPosition();
		CBlob@[] blobs;
		if (getMap().getBlobsInRadius(pos, 3, blobs))
		{
			f32 angle = this.getAngleDegrees();
			for (int i = 0; i < blobs.size(); i++)
			{
				CBlob@ blob = blobs[i];
				if (blob.hasTag("pushedByDoor"))
				{
					f32 power = 3.0f;
					f32 mass = blob.getShape().getConsts().mass;
					if (mass > 1)
					{
						power = 2.0f;
					}

					if (!faceLeft)
					{
						blob.setVelocity(Vec2f(1, 0) * power);
					}
					else
					{
						blob.setVelocity(Vec2f(-1, 0) * power);
					}

				}
			}
		}
	}

	//TODO: fix flags sync and hitting
	//SetSolidFlag(this, !open);
}

void onTick(CBlob@ this)
{
	const uint count = this.getTouchingCount();
	for (uint step = 0; step < count; ++step)
	{
		CBlob@ blob = this.getTouchingByIndex(step);
		if (blob is null) continue;

		if (canOpenDoor(this, blob) && !isOpen(this))
		{
			Vec2f pos = this.getPosition();
			Vec2f other_pos = blob.getPosition();
			Vec2f direction = Vec2f(1, 0);
			direction.RotateBy(this.getAngleDegrees());
			setOpen(this, true, ((pos - other_pos) * direction) < 0.0f);
		}
	}
	// close it
	if (isOpen(this) && canClose(this))
	{
		setOpen(this, false);
	}
}


bool canClose(CBlob@ this)
{
	const uint count = this.getTouchingCount();
	for (uint step = 0; step < count; ++step)
	{
		CBlob@ blob = this.getTouchingByIndex(step);
		if (blob.isCollidable() && !blob.getShape().isStatic()  && !blob.hasTag("pushedByDoor"))
		{
			return false;
		}
	}

	Vec2f pos = this.getPosition();
	CBlob@[] blobs;
	if (getMap().getBlobsInRadius(pos, 4, blobs))
	{
		for (int i = 0; i < blobs.size(); i++)
		{
			CBlob@ blob = blobs[i];
			if (blob.isCollidable() && !blob.getShape().isStatic() && !blob.hasTag("pushedByDoor"))
			{
				return false;
			}
		}
	}

	return true;
}

/*void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		this.getCurrentScript().tickFrequency = 3;
	}
}

void onEndCollision(CBlob@ this, CBlob@ blob)
{
	if (blob !is null)
	{
		if (canClose(this))
		{
			if (isOpen(this))
			{
				setOpen(this, false);
			}
			this.getCurrentScript().tickFrequency = 0;
		}
	}
}*/


bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

// this is such a pain - can't edit animations at the moment, so have to just carefully add destruction frames to the close animation >_>
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::boulder)
		return 0;

	//print("custom data: "+customData+" builder: "+Hitters::builder);
	if (customData == Hitters::builder)
		damage *= 2;
	if (customData == Hitters::drill)                //Hitters::saw is the drill hitter.... why //fixed
		damage *= 2;
	if (customData == Hitters::bomb)
		damage *= 1.3f;
	if (customData == Hitters::sword)
		damage *= 1.6f;

	CSprite @sprite = this.getSprite();

	if (sprite !is null)
	{
		u8 frame = 0;

		if (this.getHealth() < this.getInitialHealth())
		{
			f32 ratio = (this.getHealth() - damage * getRules().attackdamage_modifier) / this.getInitialHealth();

			if (ratio <= 0.0f)
			{
				frame = 3;
			}
			else
			{
				frame = (1.0f - ratio) * 3;
			}

			if (frame != 0)
			{
				string close_anim = "close_destruction_" + frame;
				this.set_string("close_anim", close_anim);
				if (!isOpen(this))
				{
					sprite.SetAnimation(close_anim);
					sprite.animation.SetFrameIndex(2);
				}

			}

		}

	}

	return damage;
}


bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (isOpen(this))
		return false;

	if (canOpenDoor(this, blob))
	{
		Vec2f pos = this.getPosition();
		Vec2f other_pos = blob.getPosition();
		Vec2f direction = Vec2f(1, 0);
		direction.RotateBy(this.getAngleDegrees());
		setOpen(this, true, ((pos - other_pos) * direction) < 0.0f);
		return false;
	}
	return true;
}
