#include "/Entities/Common/Attacks/Hitters.as";
#include "/Entities/Common/Attacks/LimitedAttacks.as";

const int pierce_amount = 8;

const f32 hit_amount_ground = 0.5f;
const f32 hit_amount_air = 1.0f;
const f32 hit_amount_air_fast = 3.0f;
const f32 hit_amount_cata = 10.0f;

void onInit(CBlob @ this)
{
	this.set_u8("launch team", 255);
	this.server_setTeamNum(-1);
	this.Tag("medium weight");

	LimitedAttack_setup(this);

	this.set_u8("blocks_pierced", 0);
	u32[] tileOffsets;
	this.set("tileOffsets", tileOffsets);

	// damage
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().tickFrequency = 3;
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	this.set_u8("launch team", detached.getTeamNum());
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attached.getPlayer() !is null)
	{
		this.SetDamageOwnerPlayer(attached.getPlayer());
	}

	if (attached.getName() != "catapult") // end of rock and roll
	{
		this.Untag("rock_n_roll");
	}
	this.set_u8("launch team", attached.getTeamNum());
}

void Slam(CBlob @this, f32 angle, Vec2f vel, f32 vellen)
{
	if (vellen < 0.1f)
		return;

	CMap@ map = this.getMap();
	Vec2f pos = this.getPosition();
	HitInfo@[] hitInfos;
	u8 team = this.get_u8("launch team");

	if (map.getHitInfosFromArc(pos, -angle, 30, vellen, this, true, @hitInfos))
	{
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			f32 dmg = 2.0f;

			if (hi.blob is null) // map
			{
				if (BoulderHitMap(this, hi.hitpos, hi.tileOffset, vel, dmg, Hitters::cata_boulder))
					return;
			}
			else if (team != u8(hi.blob.getTeamNum()))
			{
				this.server_Hit(hi.blob, pos, vel, dmg, Hitters::cata_boulder, true);
				this.setVelocity(vel * 0.9f); //damp

				// die when hit something large
				if (hi.blob.getRadius() > 32.0f)
				{
					this.server_Hit(this, pos, vel, 10, Hitters::cata_boulder, true);
				}
			}
		}
	}

	// chew through backwalls

	Tile tile = map.getTile(pos);
	if (map.isTileBackgroundNonEmpty(tile))
	{
		if (map.getSectorAtPosition(pos, "no build") !is null)
		{
			return;
		}
		map.server_DestroyTile(pos + Vec2f(7.0f, 7.0f), 10.0f, this);
		map.server_DestroyTile(pos - Vec2f(7.0f, 7.0f), 10.0f, this);
	}
}

bool BoulderHitMap(CBlob@ this, Vec2f worldPoint, int tileOffset, Vec2f velocity, f32 damage, u8 customData)
{
	//check if we've already hit this tile
	u32[]@ offsets;
	this.get("tileOffsets", @offsets);

	if (offsets.find(tileOffset) >= 0) { return false; }

	this.getSprite().PlaySound("ArrowHitGroundFast.ogg");
	f32 angle = velocity.Angle();
	CMap@ map = getMap();
	TileType t = map.getTile(tileOffset).type;
	u8 blocks_pierced = this.get_u8("blocks_pierced");
	bool stuck = false;

	if (map.isTileCastle(t) || map.isTileWood(t))
	{
		Vec2f tpos = this.getMap().getTileWorldPosition(tileOffset);
		if (map.getSectorAtPosition(tpos, "no build") !is null)
		{
			return false;
		}

		//make a shower of gibs here

		map.server_DestroyTile(tpos, 100.0f, this);
		Vec2f vel = this.getVelocity();
		this.setVelocity(vel * 0.8f); //damp
		this.push("tileOffsets", tileOffset);

		if (blocks_pierced < pierce_amount)
		{
			blocks_pierced++;
			this.set_u8("blocks_pierced", blocks_pierced);
		}
		else
		{
			stuck = true;
		}
	}
	else
	{
		stuck = true;
	}

	if (velocity.LengthSquared() < 5)
		stuck = true;

	if (stuck)
	{
		this.server_Hit(this, worldPoint, velocity, 10, Hitters::crush, true);
	}

	return stuck;
}

void shatter(CBlob@ this, u16 rocks_amount, f32 min_vel, f32 max_vel_inc)
{
	for (int i = 0; i < rocks_amount; i++)
		{
			CBlob@ rock = server_CreateBlob("cata_rock", this.get_u8("launch team"), this.getPosition());
			rock.Tag("fromBoulder");
			rock.Sync("fromBoulder", true);
			if (this.getDamageOwnerPlayer() !is null)
				rock.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());

			Vec2f vel = Vec2f(-(XORRandom(max_vel_inc*10)/10+min_vel),0.0f);
			f32 angle = XORRandom(3600)/10;

			vel.RotateBy(angle);
			rock.setVelocity(vel);
		}
		this.server_Die();
}


void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{

	Vec2f hitvel = this.getOldVelocity();
	f32 vellen = hitvel.Length();
	
	if (solid && getNet().isServer())
	{
		if (this.hasTag("rock_n_roll"))
		{
			shatter(this, 10, 4.0f, 4);
		}

		if (vellen > 6.0f)
		{
			shatter(this, 10, 4.0f, 4);
		}
	}

	if (solid && blob !is null)
	{
		Vec2f hitvel = this.getOldVelocity();
		Vec2f hitvec = point1 - this.getPosition();
		f32 coef = hitvec * hitvel;

		if (coef < 0.706f) // check we were flying at it
		{
			return;
		}

		f32 vellen = hitvel.Length();

		//fast enough
		if (vellen < 1.0f)
		{
			return;
		}

		u8 tteam = this.get_u8("launch team");
		CPlayer@ damageowner = this.getDamageOwnerPlayer();

		//not teamkilling (except self)
		if (damageowner is null || damageowner !is blob.getPlayer())
		{
			if (
			    (blob.getName() != this.getName() &&
			     (blob.getTeamNum() == this.getTeamNum() || blob.getTeamNum() == tteam))
			)
			{
				return;
			}
		}

		//not hitting static stuff
		if (blob.getShape() !is null && blob.getShape().isStatic())
		{
			return;
		}

		//hitting less or similar mass
		if (this.getMass() < blob.getMass() - 1.0f)
		{
			return;
		}

		//get the dmg required
		hitvel.Normalize();
		f32 dmg = vellen > 8.0f ? 5.0f : (vellen > 4.0f ? 1.5f : 0.5f);


		//hurt
		this.server_Hit(blob, point1, hitvel, dmg, Hitters::boulder, true);

		if (getNet().isServer())
		{
			if (this.hasTag("rock_n_roll") || vellen > 6.0f)
			{
				shatter(this, 10, 4.0f, 4.0f);
			}
		}

		//bounce off if not gibbed
		if (dmg < 4.0f)
		{
			this.setVelocity(blob.getOldVelocity() + hitvec * -Maths::Min(dmg * 0.33f, 1.0f));
		}

		return;

	}

}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::sword || customData == Hitters::arrow)
	{
		return damage *= 0.5f;
	}

	return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	string name = blob.getName();
	if ((name == "archer" || name == "knight" || name == "builder") && this.get_u8("launch team") == blob.getTeamNum()) return false;
	else return true;
}

//sprite

void onInit(CSprite@ this)
{
	this.animation.frame = (this.getBlob().getNetworkID() % 4);
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
