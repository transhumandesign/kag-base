// Swing Door logic

#include "Hitters.as"
#include "FireCommon.as"
#include "MapFlags.as"
#include "DoorCommon.as"

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(false);
	this.getSprite().getConsts().accurateLighting = true;

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
	this.Tag("door");
	this.Tag("blocks water");
	this.Tag("explosion always teamkill"); // ignore 'no teamkill' for explosives
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;

	this.getSprite().PlaySound("/build_door.ogg");
	
	int touchingBlobs = this.getTouchingCount();
	for (int a = 0; a < touchingBlobs; a++)
	{
		CBlob@ blob = this.getTouchingByIndex(a);
		if (blob is null)
			continue;

		if (this.getTeamNum() == blob.getTeamNum() && 
			(blob.hasTag("player") || blob.hasTag("vehicle") || blob.hasTag("migrant")))
		{
			OpenDoor(this, blob);
			break;
		}
	}
}

//TODO: fix flags sync and hitting
/*void onDie(CBlob@ this)
{
    SetSolidFlag(this, false);
}*/

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
		sprite.SetAnimation("close");
		this.getShape().getConsts().collidable = true;
		this.getCurrentScript().tickFrequency = 0;
		Sound::Play("/DoorClose.ogg", this.getPosition());
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
			OpenDoor(this, blob);
			break;
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
	uint collided = 0;
	for (uint step = 0; step < count; ++step)
	{
		CBlob@ blob = this.getTouchingByIndex(step);
		if (blob.isCollidable())
		{
			collided++;
		}
	}
	return collided == 0;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		this.getCurrentScript().tickFrequency = 3;
		if (!isOpen(this) && canOpenDoor(this, blob)) 
		{
			OpenDoor(this, blob, true);
		}
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
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::boulder)
		return 0;

	switch (customData)
	{
		case Hitters::builder:
			damage *= 2.0f;
			break;
		case Hitters::sword:
			damage *= 1.5f;
			break;
		case Hitters::bomb:
			damage *= 1.4f;
			if (hitterBlob.getTeamNum() == this.getTeamNum())
				damage *= 0.65f;
			break;
		case Hitters::drill:
			damage *= 2.0f;
			break;
		default:
			break;
	}

	if (this.hasTag("will_soon_collapse"))
	{
		damage *= 1.25f;
	}

	return damage;
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	f32 hp = this.getHealth();
	bool repaired = (hp > oldHealth);
	MakeDamageFrame(this, repaired);
}

void MakeDamageFrame(CBlob@ this, bool repaired=false)
{
	CSprite@ sprite = this.getSprite();
	f32 hp = this.getHealth();
	f32 full_hp = this.getInitialHealth();
	Animation@ destruction_anim = sprite.getAnimation("destruction");

	if (destruction_anim !is null)
	{
		int frame_count = destruction_anim.getFramesCount();
		int frame = frame_count - frame_count * (hp / full_hp);
		destruction_anim.frame = frame;

		Animation @close_anim = sprite.getAnimation("close");

		if(close_anim !is null)
		{
			close_anim.RemoveFrame(close_anim.getFramesCount() - 1);
			close_anim.AddFrame(destruction_anim.getFrame(frame));
		}

		if(repaired)
		{
			sprite.PlaySound("/build_door.ogg");
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (isOpen(this))
		return false;

	if (canOpenDoor(this, blob))
	{
		return false;
	}

	return true;
}

void OpenDoor(CBlob@ this, CBlob@ blob, bool open = true)
{
	Vec2f pos = this.getPosition();
	Vec2f other_pos = blob.getPosition();
	Vec2f direction = Vec2f(1, 0);
	direction.RotateBy(this.getAngleDegrees());
	setOpen(this, open, ((pos - other_pos) * direction) < 0.0f);
}