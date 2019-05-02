//fall damage for all characters and fall damaged items
// apply Rules "fall vel modifier" property to change the damage velocity base

#include "Hitters.as";

#include "FallDamageCommon.as";
#include "Knocked.as";

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

		// stun on fall
		const u8 knockdown_time = 12;

		if (doknockdown && getKnocked(this) < knockdown_time)
		{
			if (damage < this.getHealth()) //not dead
				Sound::Play("/BreakBone", this.getPosition());
			else
			{
				Sound::Play("/FallDeath.ogg", this.getPosition());
			}

			SetKnocked(this, knockdown_time);
		}
	}
}
