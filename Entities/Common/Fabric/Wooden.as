#include "Hitters.as"
#include "FallDamageCommon.as"

void onInit(CBlob@ this)
{
	this.Tag("wooden");

	// for things that can be protected from fall damage
	this.getCurrentScript().tickIfTag = "will_go_oof";
}

void onTick(CBlob@ this)
{
	if (!this.exists("tick_to_oof"))
	{
		this.Untag("will_go_oof");
		return;
	}

	if (getGameTime() >= this.get_u32("tick_to_oof"))
	{
		// Take damage
		this.server_Hit(this, Vec2f_zero, Vec2f_zero, this.get_f32("fall_damage"), Hitters::fall);
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.05f) //sound for all damage
	{
		f32 angle = (this.getPosition() - worldPoint).getAngle();
		if (hitterBlob !is this)
		{
			this.getSprite().PlayRandomSound("/WoodHit", Maths::Min(1.25f, Maths::Max(0.5f, damage)));
		}
		else
		{
			angle = 90.0f; // self-hit. spawn gibs upwards
		}

		makeGibParticle("/GenericGibs", worldPoint, getRandomVelocity(angle, 1.0f + damage, 90.0f) + Vec2f(0.0f, -2.0f),
		                1, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
	}

	return damage;
}


void onGib(CSprite@ this)
{
	if (this.getBlob().hasTag("heavy weight"))
	{
		this.PlaySound("/WoodDestruct");
	}
	else
	{
		this.PlaySound("/LogDestruct");
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!solid)
	{
		return;
	}

	f32 vellen = this.getShape().vellen;
	bool heavy = this.hasTag("heavy weight");
	// sound
	const f32 soundbase = heavy ? 0.7f : 2.5f;
	const f32 sounddampen = heavy ? soundbase : soundbase * 2.0f;

	if (vellen > soundbase)
	{
		f32 volume = Maths::Min(1.25f, Maths::Max(0.2f, (vellen - soundbase) / soundbase));

		if (heavy)
		{
			if (vellen > 3.0f)
			{
				this.getSprite().PlayRandomSound("/WoodHeavyHit", volume);
			}
			else
			{
				this.getSprite().PlayRandomSound("/WoodHeavyBump", volume);
			}
		}
		else
		{
			this.getSprite().PlayRandomSound("/WoodLightBump", volume);
		}
	}

	// damage
	if (!this.hasTag("ignore fall"))
	{
		const f32 base = heavy ? 5.0f : 7.0f;
		const f32 ramp = 1.2f;

		if (isServer() && vellen > base) // server only
		{
			if (vellen > base * ramp)
			{
				f32 damage = 0.0f;

				if (vellen < base * Maths::Pow(ramp, 1))
				{
					damage = 0.5f;
				}
				else if (vellen < base * Maths::Pow(ramp, 2))
				{
					damage = 1.0f;
				}
				else if (vellen < base * Maths::Pow(ramp, 3))
				{
					damage = 2.0f;
				}
				else if (vellen < base * Maths::Pow(ramp, 3))
				{
					damage = 3.0f;
				}
				else //very dead
				{
					damage = 100.0f;
				}

				if (!isSavableFromFall(this))
				{
					this.server_Hit(this, point1, normal, damage, Hitters::fall);
				}
				else
				{
					if (isSavedFromFall(this)) return;

					if (shouldFallDamageWait(point1, this))
					{
						// store damage
						this.set_f32("fall_damage", damage);

						this.Tag("will_go_oof");
						this.set_u32("tick_to_oof", getGameTime() + 2);
					}
					else
					{
						this.server_Hit(this, point1, normal, damage, Hitters::fall);
					}
				}
			}
		}
	}
}
