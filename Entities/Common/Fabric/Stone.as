#include "Hitters.as"

void onInit(CBlob@ this)
{
	this.Tag("stone");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.05f) //sound for all damage
	{
		if (hitterBlob !is this)
		{
			this.getSprite().PlaySound("dig_stone", Maths::Min(1.25f, Maths::Max(0.5f, damage)));
		}

		makeGibParticle("GenericGibs", worldPoint, getRandomVelocity((this.getPosition() - worldPoint).getAngle(), 1.0f + damage, 90.0f) + Vec2f(0.0f, -2.0f),
		                2, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
	}

	return damage;
}


void onGib(CSprite@ this)
{
	if (this.getBlob().hasTag("heavy weight"))
	{
		this.PlaySound("WoodDestruct");
	}
	else
	{
		this.PlaySound("LogDestruct");
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!solid
		|| !isServer())
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

	const f32 base = heavy ? 5.0f : 7.0f;
	const f32 ramp = 1.2f;

	//print("stone vel " + vellen + " base " + base );
	// damage
	if (isServer() && vellen > base && !this.hasTag("ignore fall"))
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

			this.server_Hit(this, point1, normal, damage, Hitters::fall);
		}
	}
}
