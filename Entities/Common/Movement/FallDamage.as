//fall damage for all characters and fall damaged items
// apply Rules "fall vel modifier" property to change the damage velocity base

#include "Hitters.as";
#include "KnockedCommon.as";
#include "FallDamageCommon.as";

const u8 knockdown_time = 12;

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!solid || this.isInInventory())
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
		bool doknockdown = true;

		if (damage > 0.0f)
		{
			// check if we aren't touching a trampoline
			CBlob@[] overlapping;

			if (this.getOverlapping(@overlapping))
			{
				for (uint i = 0; i < overlapping.length; i++)
				{
					CBlob@ b = overlapping[i];

					if (b.hasTag("no falldamage"))
					{
						return;
					}
				}
			}

			if (damage > 0.1f)
			{
				this.server_Hit(this, point1, normal, damage, Hitters::fall);
			}
			else
			{
				doknockdown = false;
			}
		}

		if (getGameTime() == this.get_u32("death sound time stamp") && doknockdown && setKnocked(this, knockdown_time))
		{
			if (damage < this.getHealth()) //not dead
				Sound::Play("/BreakBone", this.getPosition());
			else
			{
				Sound::Play("/FallDeath.ogg", this.getPosition());
			}
		}
	}
}

void onHealthChange(CBlob@ this, f32 health_old)
{
	if (health_old > 0.0f)
	{
		this.set_u32("death sound time stamp", getGameTime());
	}
}
