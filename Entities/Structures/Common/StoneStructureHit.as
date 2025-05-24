//scale the damage:
//      knights, arrows and fire doesn't deal damage

#include "Hitters.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 dmg = damage;
	switch (customData)
	{
		case Hitters::builder:
			dmg *= 2.0f; //builder is great at smashing stuff
			break;

		case Hitters::sword:
		case Hitters::arrow:
		case Hitters::stab:
		case Hitters::fire:
			dmg = 0.0f;
			break;

		case Hitters::bomb:
			dmg *= 0.5f;
			break;

		case Hitters::keg:
		case Hitters::explosion:
			dmg *= 2.5f;
			break;

		case Hitters::bomb_arrow:
			dmg *= 8.0f;
			break;

		case Hitters::cata_stones:
			dmg *= 5.0f;
			break;
		case Hitters::crush:
			dmg *= 4.0f;
			break;

		case Hitters::flying: // boat ram
			dmg *= 7.0f;
			break;
	}

	return dmg;
}
