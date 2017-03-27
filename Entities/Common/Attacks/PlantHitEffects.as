
#include "Hitters.as"

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.05f) //sound for all damage
	{
		//read customdata for hitter
		switch (customData)
		{
			case 0: //in case we want more cases
			default:
				if (hitterBlob !is this)
				{
					Sound::Play("/cut_grass", this.getPosition());
				}

				for (int i = 0; i < (damage + 1); ++i)
				{
					makeGibParticle("GenericGibs",
					                this.getPosition(), getRandomVelocity(-90, (Maths::Min(Maths::Max(0.5f, damage), 2.0f) * 4.0f) , 270),
					                7, 3 + XORRandom(4), Vec2f(8, 8),
					                1.0f, 0, "", 0);
				}

				break;
		}
	}

	return damage;
}

