#include "/Entities/Common/Attacks/Hitters.as";
#include "/Entities/Common/Attacks/LimitedAttacks.as";
#include "MakeDustParticle.as"

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
		this.Untag("fragment on collide");
	}
	this.set_u8("launch team", attached.getTeamNum());
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (this.hasTag("fragment on collide"))
	{
		if (!solid) { return; }

		Vec2f hitVelocity = this.getOldVelocity();

		Vec2f hitvec = point1 - this.getPosition();
		f32 coef = hitvec * hitVelocity;

		if (coef < 0.706f) // check we were flying at it
		{
			return;
		}

		Vec2f normalizedHitVelocity = hitVelocity;
		normalizedHitVelocity.Normalize();

		Random r(this.getNetworkID());
		for (int i = 0; i < 20; ++i)
		{
			const float maxDistanceFromOrigin = 5.0; // spawn the fragment from that far of the origin at a maximum
			const float baseVelocityAmplitude = 1.5; // how much velocity the fragment will inherit from the boulder
			const float velocityJitterAmplitude = hitVelocity.Length() * 0.3; // how much we randomize the velocity

			Vec2f positionJitter = Vec2f(r.NextFloat() - 0.5, r.NextFloat() - 0.5) * 2.0 * maxDistanceFromOrigin;
			Vec2f rockPosition = (this.getPosition() - hitVelocity * (r.NextFloat() - 0.3) * 6.0) + positionJitter;

			Vec2f baseVelocity = hitVelocity * baseVelocityAmplitude;
			Vec2f velocityJitter = Vec2f(r.NextFloat() - 0.5, r.NextFloat() * 0.5) * velocityJitterAmplitude;
			Vec2f rockVelocity = baseVelocity + velocityJitter;

			if (isServer())
			{
				CBlob@ rock = server_CreateBlob("cata_rock", this.getTeamNum(), rockPosition);
				rock.Untag("can ricochet");
				rock.setVelocity(rockVelocity);
				rock.server_SetTimeToDie(1);
				rock.server_SetHealth(0.5f);
			}
			
			if (isClient())
			{
				MakeRockDustParticle(
					rockPosition,
					"Smoke.png",
					rockVelocity * 0.1 * ((r.NextFloat()) + 0.5),
					XORRandom(9) + 3);
			}
		}

		if (isClient())
		{
			Sound::Play("dig_stone?.ogg", this.getPosition(), 1.3f);
			Sound::Play("metal_stone.ogg", this.getPosition(), 1.3f);
		}

		this.server_Die();
		return;
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

		//bounce off if not gibbed
		if (dmg < 4.0f)
		{
			this.setVelocity(blob.getOldVelocity() + hitvec * -Maths::Min(dmg * 0.33f, 1.0f));
		}

		//hurt
		this.server_Hit(blob, point1, hitvel, dmg, Hitters::boulder, true);

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

//sprite

void onInit(CSprite@ this)
{
	this.animation.frame = (this.getBlob().getNetworkID() % 4);
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
