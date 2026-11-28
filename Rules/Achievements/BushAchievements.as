#define CLIENT_ONLY

#include "hitters.as"

void onHit(CBlob@ this,  Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	CSteamAchievements@ ach = getSteamAchievements();
	CBlob@ playerBlob = getLocalPlayerBlob();

	if (ach is null || playerBlob is null)
		return;

	if (playerBlob is hitterBlob
			&& customData == Hitters::sword
			&& damage == 1.0f)
		ach.Unlock(Steam::STAB_SHRUB);
}