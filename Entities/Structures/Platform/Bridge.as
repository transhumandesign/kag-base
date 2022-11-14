#include "Hitters.as"

#include "FireCommon.as"

void onInit(CBlob@ this)
{
	this.Tag("place norotate");

	this.Tag("explosion always teamkill"); // ignore 'no teamkill' for explosives

	this.SetFacingLeft(XORRandom(128) > 64);

	this.getShape().getConsts().waterPasses = true;

	CShape@ shape = this.getShape();
	shape.AddPlatformDirection(Vec2f(0, -1), 89, false);
	shape.SetRotationsAllowed(false);

	//this.server_setTeamNum(-1); //allow anyone to break them
	this.set_TileType("background tile", CMap::tile_wood_back);
	this.set_s16(burn_duration , 300);
	//transfer fire to underlying tiles
	this.Tag(spread_fire_tag);

	if (getNet().isServer())
	{
		dictionary harvest;
		harvest.set('mat_wood', 4);
		this.set('harvest', harvest);
	}

	MakeDamageFrame(this);
	this.getCurrentScript().tickFrequency = 0;
	this.set_u32("open_time", 0);
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	f32 hp = this.getHealth();
	bool repaired = (hp > oldHealth);
	MakeDamageFrame(this, repaired);
}

void MakeDamageFrame(CBlob@ this, bool repaired = false)
{
	f32 hp = this.getHealth();
	f32 full_hp = this.getInitialHealth();
	int frame_count = this.getSprite().animation.getFramesCount();
	int frame = frame_count - frame_count * (hp / full_hp);
	this.getSprite().animation.frame = frame;

	if (repaired)
	{
		this.getSprite().PlaySound("/build_wood.ogg");
	}
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;

	this.getCurrentScript().tickFrequency = 3;
	this.getSprite().PlaySound("/build_wood.ogg");
}

bool isOpen(CBlob@ this)
{
	return !this.getShape().getConsts().collidable;
}

void setOpen(CBlob@ this, bool open)
{
	bool is_open = isOpen(this);
	if (is_open == open)
	{
		if (is_open)
		{
			this.set_u32("open_time", getGameTime());
		}

		return;
	}

	CSprite@ sprite = this.getSprite();
	CShape@ shape = this.getShape();

	if (open)
	{
		sprite.SetZ(-100.0f);
		sprite.SetAnimation("open");
		shape.getConsts().collidable = false;
		sprite.PlaySound("bridge_open.ogg");
		this.set_u32("open_time", getGameTime());

	}
	else
	{
		sprite.SetZ(100.0f);
		sprite.SetAnimation("destruction");
		shape.getConsts().collidable = true;
		sprite.PlaySound("bridge_close.ogg");

	}

	MakeDamageFrame(this);

	// setAdjacentOpen(this, open);

}

/*void setAdjacentOpen(CBlob@ this, bool open)
{
	CMap@ map = getMap();
	if (map !is null)
	{
		Vec2f pos = this.getPosition();
		CBlob@[] blobs;
		if (map.getBlobsInBox(pos - Vec2f(8, 0), pos + Vec2f(8, 0), blobs))
		{
			for (int i = 0; i < blobs.size(); i++)
			{
				CBlob@ blob = blobs[i];
				if (blob.getName() == "bridge" && blob.getTeamNum() == this.getTeamNum() && blob.getPosition().y == pos.y)
				{
					if (isOpen(blob) != open)
					{
						setOpen(blob, open);
					}

				}

			}

		}
	}

}*/

void onTick(CBlob@ this)
{
	if (shouldOpen(this))
	{
		setOpen(this, true);

	}
	else
	{
		u32 open_time = this.get_u32("open_time");
		u32 ticks_since_open = getGameTime() - open_time;
		if (ticks_since_open < 10)
		{
			return;
		}

		setOpen(this, false);

	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (isOpen(this))
	{
		return false;
	}

	if (canOpen(this, blob))
	{
		setOpen(this, true);
		return false;
	}

	return true;
}

bool canOpen(CBlob@ this, CBlob@ blob)
{
	if (this.getTeamNum() != blob.getTeamNum()
		&& blob.getShape().getConsts().collidable
		&& (blob.hasTag("player") || blob.hasTag("dead player") || blob.hasTag("vehicle")))
	{
		return true;

	}
	return false;
}

bool shouldOpen(CBlob@ this)
{
	const uint count = this.getTouchingCount();
	for (uint step = 0; step < count; ++step)
	{
		CBlob@ blob = this.getTouchingByIndex(step);
		if (canOpen(this, blob))
		{
			return true;
		}
	}

	Vec2f pos = this.getPosition();
	CBlob@[] blobs;
	if (getMap().getBlobsInRadius(pos, 4, blobs))
	{
		for (int i = 0; i < blobs.size(); i++)
		{
			CBlob@ blob = blobs[i];
			if (canOpen(this, blob))
			{
				return true;
			}
		}
	}

	return false;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}
