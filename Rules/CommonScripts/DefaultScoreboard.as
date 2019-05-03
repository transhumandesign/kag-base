
// set kills, deaths and assists

#include "AssistCommon.as";

void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (!this.isGameOver() && !this.isWarmup())	//Only count kills, deaths and assists when the game is on
	{
		if (blob !is null)
		{
			CPlayer@ killer = blob.getPlayerOfRecentDamage();
			CPlayer@ victim = blob.getPlayer();
			CPlayer@ helper = getAssistPlayer(victim, killer);

			if (helper !is null)
			{
				helper.setAssists(helper.getAssists() + 1);
			}

			if (victim !is null)
			{
				victim.setDeaths(victim.getDeaths() + 1);
				// temporary until we have a proper score system
				victim.setScore(100 * (f32(victim.getKills()) / f32(victim.getDeaths() + 1)));

				if (killer !is null) //requires victim so that killing trees matters
				{
					if (killer.getTeamNum() != blob.getTeamNum())
					{
						killer.setKills(killer.getKills() + 1);
						// temporary until we have a proper score system
						killer.setScore(100 * (f32(killer.getKills()) / f32(killer.getDeaths() + 1)));
					}
				}

			}

		}

	}
	
}
