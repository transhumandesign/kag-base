
//if we were unable to hit something, fleck some sparks off it and play a ding sound.

#include "ParticleSparks.as";

bool noSound(CBlob@ b)
{
	if (b.hasTag("flesh") ||
	        b.hasTag("material") ||
	        b.getTeamNum() == -1)
		return true;

	string name = b.getName();

	return name == "arrow" || name == "heart" || name == "seed" || name == "food";
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (damage <= 0.0f && hitBlob.getTeamNum() != this.getTeamNum() && !noSound(hitBlob))
	{
		Vec2f pos = worldPoint;

		Sound::Play("Entities/Characters/Knight/ShieldHit.ogg", pos);
		sparks(pos, -velocity.Angle(), 0.1f);
	}
}
