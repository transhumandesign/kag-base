#include "Hitters.as"

enum facing_direction
{
	none = 0,
	up,
	down,
	left,
	right
};

const string facing_prop = "facing";

enum spike_state
{
	normal = 0,
	hidden,
	stabbing,
	falling
};

const string state_prop = "popup state";
const string timer_prop = "popout timer";
const u8 delay_stab = 10;
const u8 delay_retract = 30;

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;	 // we have our own map collision

	this.Tag("place norotate");

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	//dont set radius flags here so we orient to the ground first

	this.set_u8(facing_prop, up);

	this.set_u8(state_prop, normal);
	this.set_u8(timer_prop, 0);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;

	this.getSprite().PlaySound("/build_wall2.ogg");
}

//temporary struct used to pass some variables by reference
//since &inout isn't supported for native types
class spikeCheckParameters
{
	facing_direction facing;
	bool onSurface, placedOnStone;
};

//specific tile checking logic for the spikes
void tileCheck(CBlob@ this, CMap@ map, Vec2f pos, f32 angle, facing_direction set_facing, spikeCheckParameters@ params)
{
	if (params.placedOnStone) return; //do nothing if we've already found stone

	TileType t = map.getTile(pos).type;

	if (params.onSurface)
	{
		if (map.isTileCastle(t))
		{
			params.facing = set_facing;
			this.setAngleDegrees(angle);
			params.placedOnStone = true;
		}
	}
	else if (map.isTileSolid(t))
	{
		params.onSurface = true;
		params.facing = set_facing;
		this.setAngleDegrees(angle);
		params.placedOnStone = map.isTileCastle(t);
	}
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();
	const f32 tilesize = map.tilesize;

	if (getNet().isServer() &&
	        (map.isTileSolid(map.getTile(pos)) || map.rayCastSolid(pos - this.getVelocity(), pos)))
	{
		this.server_Hit(this, pos, Vec2f(0, -1), 3.0f, Hitters::fall, true);
		return;
	}

	//get prop
	spike_state state = spike_state(this.get_u8(state_prop));
	if (state == falling) //opt
	{
		this.getCurrentScript().runFlags &= ~Script::tick_blob_in_proximity;
		this.getCurrentScript().tickFrequency = 1;
		this.getShape().SetStatic(false);
		this.setAngleDegrees(180);
		return;
	}

	//check support/placement status
	facing_direction facing;
	bool placedOnStone;
	bool onSurface;

	//wrapped functionality
	{
		spikeCheckParameters temp;
		//box
		temp.facing = none;
		temp.onSurface = temp.placedOnStone = false;

		tileCheck(this, map, pos + Vec2f(0.0f, tilesize), 0.0f, up, temp);
		tileCheck(this, map, pos + Vec2f(-tilesize, 0.0f), 90.0f, right, temp);
		tileCheck(this, map, pos + Vec2f(tilesize, 0.0f), -90.0f, left, temp);
		tileCheck(this, map, pos + Vec2f(0.0f, -tilesize), 180.0f, down, temp);

		//unbox
		facing = temp.facing;
		placedOnStone = temp.placedOnStone;
		onSurface = temp.onSurface;
	}

	if (!onSurface && getNet().isServer())
	{
		this.getCurrentScript().runFlags &= ~Script::tick_blob_in_proximity;
		this.getCurrentScript().tickFrequency = 1;
		this.getShape().SetStatic(false);

		facing = down;
		state = falling;
	}

	if (state == falling)
	{
		this.set_u8(state_prop, state);
		this.Sync(state_prop, true);
		return;
	}

	if (getNet().isClient() && !this.hasTag("_frontlayer"))
	{
		CSprite@ sprite = this.getSprite();
		sprite.SetZ(500.0f);

		if (sprite !is null)
		{
			CSpriteLayer@ panel = sprite.addSpriteLayer("panel", sprite.getFilename() , 8, 16, this.getTeamNum(), this.getSkinNum());

			if (panel !is null)
			{
				panel.SetOffset(Vec2f(0, 3));
				panel.SetRelativeZ(500.0f);

				Animation@ animcharge = panel.addAnimation("default", 0, false);
				animcharge.AddFrame(6);
				animcharge.AddFrame(7);

				this.Tag("_frontlayer");
			}
		}
	}

	this.set_u8(facing_prop, facing);

	u8 timer = this.get_u8(timer_prop);

	// set optimisation flags - not done in oninit so we actually orient to the stone first

	this.getCurrentScript().runProximityRadius = 124.0f;
	this.getCurrentScript().runFlags |= Script::tick_blob_in_proximity;

	// spike'em

	if (placedOnStone)
	{
		const u32 tickFrequency = 3;
		this.getCurrentScript().tickFrequency = tickFrequency;

		if (state == hidden)
		{
			this.getSprite().SetAnimation("hidden");
			CBlob@[] blobsInRadius;
			const int team = this.getTeamNum();
			if (map.getBlobsInRadius(pos, this.getRadius() * 1.0f, @blobsInRadius))
			{
				for (uint i = 0; i < blobsInRadius.length; i++)
				{
					CBlob @b = blobsInRadius[i];
					if (team != b.getTeamNum() && canStab(b))
					{
						state = stabbing;
						timer = delay_stab;

						break;
					}
				}
			}
		}
		else if (state == stabbing)
		{
			if (timer >= tickFrequency)
			{
				timer -= tickFrequency;
			}
			else
			{
				state = normal;
				timer = delay_retract;

				this.getSprite().SetAnimation("default");
				this.getSprite().PlaySound("/SpikesOut.ogg");

				CBlob@[] blobsInRadius;
				const int team = this.getTeamNum();
				if (map.getBlobsInRadius(pos, this.getRadius() * 2.0f, @blobsInRadius))
				{
					for (uint i = 0; i < blobsInRadius.length; i++)
					{
						CBlob @b = blobsInRadius[i];
						if (canStab(b)) //even hurts team when stabbing
						{
							// hurt?
							if (this.isOverlapping(b))
							{
								this.server_Hit(b, pos, b.getVelocity() * -1, 0.5f, Hitters::spikes, true);
							}
						}
					}
				}
			}
		}
		else //state is normal
		{
			if (timer >= tickFrequency)
			{
				timer -= tickFrequency;
			}
			else
			{
				state = hidden;
				timer = 0;
			}
		}
		this.set_u8(state_prop, state);
		this.set_u8(timer_prop, timer);
	}
	else
	{
		this.getCurrentScript().tickFrequency = 25;
		this.getSprite().SetAnimation("default");
		this.set_u8(state_prop, 0);
		this.set_u8(timer_prop, 0);
	}

	onHealthChange(this, this.getHealth());
}

bool canStab(CBlob@ b)
{
	return !b.hasTag("dead") && b.hasTag("flesh");
}

//physics logic
void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point)
{
	if (!getNet().isServer() || this.isAttached())
	{
		return;
	}

	//shouldn't be in here! collided with map??
	if (blob is null)
	{
		return;
	}

	u8 state = this.get_u8(state_prop);
	if (state == hidden || state == stabbing)
	{
		return;
	}

	// only hit living things
	if (!blob.hasTag("flesh"))
	{
		return;
	}

	if (state == falling)
	{
		float vellen = this.getVelocity().Length();
		if (vellen < 4.0f) //slow, minimal dmg
			this.server_Hit(blob, point, Vec2f(0, 1), 1.0f, Hitters::spikes, true);
		else if (vellen < 5.5f) //faster, kill archer
			this.server_Hit(blob, point, Vec2f(0, 1), 2.0f, Hitters::spikes, true);
		else if (vellen < 7.0f) //faster, kill builder
			this.server_Hit(blob, point, Vec2f(0, 1), 3.0f, Hitters::spikes, true);
		else			//fast, instakill
			this.server_Hit(blob, point, Vec2f(0, 1), 4.0f, Hitters::spikes, true);
		return;
	}

	f32 damage = 0.0f;

	f32 angle = this.getAngleDegrees();
	Vec2f vel = blob.getOldVelocity(); //if we use current vel it might have been cancelled vs terrain

	bool b_falling = Maths::Abs(vel.y) > 0.5f;

	if (angle > -135.0f && angle < -45.0f)
	{
		f32 verDist = Maths::Abs(this.getPosition().y - blob.getPosition().y);

		if (normal.x > 0.5f && verDist < 6.1f && vel.x > 1.0f)
		{
			damage = 1.0f;
		}
		else if (b_falling && vel.x >= 0)
		{
			damage = 0.5f;
		}
	}
	else if (angle > 45.0f && angle < 135.0f)
	{
		f32 verDist = Maths::Abs(this.getPosition().y - blob.getPosition().y);

		if (normal.x < -0.5f && verDist < 6.1f && vel.x < -1.0f)
		{
			damage = 1.0f;
		}
		else if (b_falling && vel.x <= 0)
		{
			damage = 0.5f;
		}
	}
	else if (angle <= -135.0f || angle >= 135.0f)
	{
		f32 horizDist = Maths::Abs(this.getPosition().x - blob.getPosition().x);

		if (normal.y < -0.5f && horizDist < 6.1f && vel.y < -0.5f)
		{
			damage = 1.0f;
		}
	}
	else
	{
		f32 horizDist = Maths::Abs(this.getPosition().x - blob.getPosition().x);

		if (normal.y > 0.5f && horizDist < 6.1f && vel.y > 0.5f)
		{
			damage = 1.0f;
		}
		else if (this.getVelocity().y > 0.5f && horizDist < 6.1f)  // falling down
		{
			damage = this.getVelocity().y * 2.0f;
		}
	}

	if (damage > 0)
	{
		this.server_Hit(blob, point, vel * -1, damage, Hitters::spikes, true);
	}
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (hitBlob !is null && hitBlob !is this && damage > 0.0f)
	{
		CSprite@ sprite = this.getSprite();
		sprite.PlaySound("/SpikesCut.ogg");

		if (!this.hasTag("bloody"))
		{
			if (!g_kidssafe)
			{
				sprite.animation.frame += 3;
			}

			this.Tag("bloody");
		}
	}
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	f32 hp = this.getHealth();
	f32 full_hp = this.getInitialHealth();
	int frame = (hp > full_hp * 0.9f) ? 0 : ((hp > full_hp * 0.4f) ? 1 : 2);

	if (this.hasTag("bloody") && !g_kidssafe)
	{
		frame += 3;
	}
	this.getSprite().animation.frame = frame;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 dmg = damage;
	switch (customData)
	{
		case Hitters::bomb:
			dmg *= 0.5f;
			break;

		case Hitters::keg:
			dmg *= 2.0f;
			break;

		case Hitters::arrow:
			dmg = 0.0f;
			break;

		case Hitters::cata_stones:
			dmg *= 3.0f;
			break;
	}
	return dmg;
}
