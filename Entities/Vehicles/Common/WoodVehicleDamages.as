#include "Hitters.as";
#include "GameplayEvents.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 dmg = damage;

	switch (customData)
	{
		case Hitters::builder:
			dmg *= 2.0f;
			break;

		case Hitters::sword:
			if (dmg <= 1.0f)
			{
				dmg = 0.25f;
			}
			else
			{
				dmg = 0.5f;
			}
			break;

		case Hitters::bomb:
			dmg *= 1.40f;
			break;

		case Hitters::explosion:
			dmg *= 4.5f;
			break;

		case Hitters::bomb_arrow:
			dmg *= 8.0f;
			break;

		case Hitters::arrow:
			dmg = this.getMass() > 1000.0f ? 1.0f : 0.5f;
			break;

		case Hitters::ballista:
			dmg *= 2.0f;
			break;
	}

	if (dmg > 0 && hitterBlob !is null && hitterBlob !is this)
	{
		CPlayer@ damageowner = hitterBlob.getDamageOwnerPlayer();
		if (damageowner !is null)
		{
			if (damageowner.getTeamNum() != this.getTeamNum())
			{
				SendGameplayEvent(createVehicleDamageEvent(damageowner, dmg));
			}
		}
	}

	return dmg;
}

void onDie(CBlob@ this)
{
	CPlayer@ p = this.getPlayerOfRecentDamage();
	if (p !is null)
	{
		CBlob@ b = p.getBlob();
		if (b !is null && b.getTeamNum() != this.getTeamNum())
		{
			SendGameplayEvent(createVehicleDestroyEvent(this.getPlayerOfRecentDamage()));
		}
	}
}
