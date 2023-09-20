//fall damage for all characters and fall damaged items
// apply Rules "fall vel modifier" property to change the damage velocity base

#include "Hitters.as";
#include "KnockedCommon.as";
#include "FallDamageCommon.as";

const u8 knockdown_time = 12;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickIfTag = "will_go_oof";
	this.set_u32("safe_from_fall", 0); // Tick to prevent fall damage
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!solid || this.isInInventory() || this.hasTag("invincible"))
	{
		return;
	}

	if (blob !is null && (blob.hasTag("player") || blob.hasTag("no falldamage")))
	{
		return; //no falldamage when stomping
	}

	f32 vely = this.getOldVelocity().y;

	if (vely < 0 || Maths::Abs(normal.x) > Maths::Abs(normal.y) * 2) { return; }

	f32 damage = FallDamageAmount(vely);
	if (damage != 0.0f) //interesting value
	{
		bool wait_to_oof = false;
		CBlob@[] groundblobs;
		if (getMap().getBlobsInRadius(point1, this.getRadius(), @groundblobs))
		{
			for (int i = 0; i < groundblobs.length; ++i)
			{
				CBlob@ b = groundblobs[i];

				if (b.hasTag("no falldamage"))
				{
					if (getGameTime() - this.get_u32("safe_from_fall") <= 1)
					{
						return;
					}
					wait_to_oof = true;
				}
			}
		}

		if (wait_to_oof)
		{
			FallInfo fall(point1, normal, damage, getGameTime());
			this.set("fallInfo", @fall);
			this.Tag("will_go_oof");
		}
		else
		{
			Oof(this, point1, normal, damage);
		}
	}
}

void onTick(CBlob@ this)
{
	FallInfo@ fall;
	if (!this.get("fallInfo", @fall)) return;

	// Wait a tick
	if (getGameTime() - fall.tick < 2) return;

	this.Untag("will_go_oof");
	Oof(this, fall.pos, fall.vel, fall.damage);
}

void Oof(CBlob@ this, Vec2f pos, Vec2f vel, f32 damage)
{
	if (!this.hasTag("dead"))
	{				
		if (this.getHealth() > damage) //not dead
			Sound::Play("/BreakBone", this.getPosition());
		else
		{
			Sound::Play("/FallDeath.ogg", this.getPosition());
		}
	}

	if (damage > 0.1f)
	{
		this.server_Hit(this, pos, vel, damage, Hitters::fall);
	}

	setKnocked(this, knockdown_time);
}
