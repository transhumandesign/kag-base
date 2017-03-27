
//war base hitting

#include "/Entities/Common/Attacks/Hitters.as";
#include "FireParticle.as";


bool actorHit(u8 type)
{
	return type == Hitters::builder ||
	       type == Hitters::sword ||
	       type == Hitters::shield ||
	       type == Hitters::bomb ||
	       type == Hitters::stab ||
	       type == Hitters::arrow ;
}

bool siegeHit(u8 type)
{
	return type == Hitters::cata_stones ||
	       type == Hitters::ballista;
}

bool explosiveHit(u8 type)
{
	return
	    type == Hitters::explosion;
}

bool normalHit(u8 type)
{
	return
	    type == Hitters::burn;
}

// lets detect fast projectiles here

void DetectProjectiles(CBlob@ this)
{
	CBlob@[] overlapping;

	if (this.getOverlapping(@overlapping))
	{
		for (uint i = 0; i < overlapping.length; i++)
		{
			CBlob@ b = overlapping[i];
			if (!b.isOnGround() && b.getTeamNum() != this.getTeamNum())
			{
				u8 hitter = 0;
				f32 dam = 0.0f;

				const f32 vellen = b.getShape().vellen;

				if (vellen > 2.0f)
				{
					const string b_name = b.getName();
					if (b_name == "arrow" && vellen > 5.0f)
					{
						hitter = Hitters::arrow;
						dam = 0.25f;
					}
					else if (b_name == "ballista_bolt")
					{
						hitter = Hitters::ballista;
						dam = 1.5f;
					}
					else if (b_name == "cata_rock")
					{
						hitter = Hitters::cata_stones;
						dam = 0.25f;
					}
					else if (b_name == "boulder" && vellen > 8.0f)
					{
						hitter = Hitters::cata_stones;
						dam = 1.5f;
					}
				}

				if (hitter != 0)
				{
					b.setPosition(b.getPosition() + b.getVelocity() * b.getRadius());

					b.server_Hit(this, b.getPosition(), b.getVelocity(), dam, 0, true);
					b.server_SetHealth(-1.0f);
					b.server_Die();
				}
			}
		}
	}
}

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 3;
}

void onTick(CBlob@ this)
{
	if (getNet().isServer())
	{
		DetectProjectiles(this);
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getTeamNum() == this.getTeamNum() && hitterBlob !is this)
	{
		return 0.0f;
	}

	this.set_u8("alert_time", 30);

	if (damage > 0.001f)
	{
		//   print("base dmg " + damage + " health " + this.getHealth() );
		makeSmokeParticle(worldPoint + Vec2f(XORRandom(8) - 4, XORRandom(8) - 4));
		this.getSprite().PlaySound("BaseHitSound.ogg");
		ShakeScreen(3.0f, 8, worldPoint);
	}
	else { return damage; }

	if (normalHit(customData))
	{
		return damage;
	}

	if (actorHit(customData))
	{
		return Maths::Min(damage * 0.5f, 1.0f);
	}

	if (siegeHit(customData))
	{
		return Maths::Min(damage * 2.0f , 3.0f);
	}

	if (explosiveHit(customData))
	{
		return Maths::Min(damage * 3.0f, 7.0f);
	}

	return damage;
}


