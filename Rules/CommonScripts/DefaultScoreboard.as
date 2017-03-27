
// set kills and deaths

void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (blob !is null)
	{
		CPlayer@ killer = blob.getPlayerOfRecentDamage();
		CPlayer@ victim = blob.getPlayer();

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
