//scale the damage:
//      builders do extra
//      knights only damage with slashes
//      arrows do half

#include "Hitters.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 dmg = damage;

	switch (customData)
	{
		case Hitters::builder:
			dmg *= 2.0f;
			break;

		case Hitters::sword:
		case Hitters::arrow:
		case Hitters::stab:

			if (dmg <= 1.0f)
			{
				dmg = 0.125f;
			}
			else
			{
				dmg *= 0.25f;
			}
			break;

		case Hitters::burn:
			dmg = 1.0f;
			break;

		case Hitters::bomb:
			dmg *= 1.40f;
			break;

		case Hitters::explosion:
			if (this.hasTag("bombResistant"))
			{
				dmg *= 1.4f;
			}
			else
			{
				dmg *= 2.5f;
			}
			break;

		case Hitters::bomb_arrow:
			if (this.hasTag("bombResistant"))
			{
				dmg *= 1.7f;
			}
			else
			{
				dmg *= 8.0f;
			}

			break;

		case Hitters::cata_stones:
		case Hitters::crush:
		case Hitters::cata_boulder:
			dmg *= 4.0f;
			break;

		case Hitters::flying: // boat ram
			dmg *= 8.0f;
			break;
	}

	return dmg;
}
