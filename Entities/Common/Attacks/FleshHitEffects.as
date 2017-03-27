
#include "Hitters.as"

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.1f && (hitterBlob !is this || customData == Hitters::crush))  //sound for anything actually painful
	{
		f32 capped_damage = Maths::Min(damage, 2.0f);

		//set this false if we whouldn't show blood effects for this hit
		bool showblood = true;

		//read customdata for hitter
		switch (customData)
		{
			case Hitters::drown:
			case Hitters::burn:
			case Hitters::fire:
				showblood = false;
				break;

			case Hitters::sword:
				Sound::Play("SwordKill", this.getPosition());
				break;

			case Hitters::stab:
				if (this.getHealth() > 0.0f && damage > 2.0f)
				{
					this.Tag("cutthroat");
				}
				break;

			default:
				if (customData != Hitters::bite)
					Sound::Play("FleshHit.ogg", this.getPosition());
				break;
		}

		worldPoint.y -= this.getRadius() * 0.5f;

		if (showblood)
		{
			if (capped_damage > 1.0f)
			{
				ParticleBloodSplat(worldPoint, true);
			}

			if (capped_damage > 0.25f)
			{
				for (f32 count = 0.0f ; count < capped_damage; count += 0.5f)
				{
					ParticleBloodSplat(worldPoint + getRandomVelocity(0, 0.75f + capped_damage * 2.0f * XORRandom(2), 360.0f), false);
				}
			}

			if (capped_damage > 0.01f)
			{
				f32 angle = (velocity).Angle();

				for (f32 count = 0.0f ; count < capped_damage + 0.6f; count += 0.1f)
				{
					Vec2f vel = getRandomVelocity(angle, 1.0f + 0.3f * capped_damage * 0.1f * XORRandom(40), 60.0f);
					vel.y -= 1.5f * capped_damage;
					ParticleBlood(worldPoint, vel * -1.0f, SColor(255, 126, 0, 0));
					ParticleBlood(worldPoint, vel * 1.7f, SColor(255, 126, 0, 0));
				}
			}
		}
	}

	return damage;
}

