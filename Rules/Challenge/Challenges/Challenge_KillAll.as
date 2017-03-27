#include "ChallengesCommon.as"

void onInit(CMap@ this)
{
	CRules@ rules = getRules();
	SetIntroduction(rules, "Kill'em All!");

	if (getNet().isServer())
	{
		rules.set_bool("repeat if dead", true);

		// make stats file
		Stats_MakeFile(rules, "killall");
		ConfigFile stats;
		if (!stats.loadFile("../Cache/" + g_statsFile))
		{
			Stats_Add_TeamTimeMeasures(stats);
			Stats_Add_KillMeasures(stats);

			stats.saveFile(g_statsFile);
		}
	}

	AddRulesScript(rules);
}

void onTick(CMap@ this)
{
	CRules@ rules = getRules();

	if (getNet().isServer())
	{
		if (rules.isGameOver())
		{
			// sync stats

			if (!syncedStats)
			{
				ConfigFile stats;
				string output;
				if (stats.loadFile("../Cache/" + g_statsFile))
				{
					output += Stats_Begin_Output();
					output += Stats_Output_TeamTimeMeasures(stats, false);
					output += Stats_Output_KillMeasures(stats);

					Stats_Send(rules, output);
				}
				syncedStats = true;
			}

			return;
		}
	}
}

void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	// reset stats

	if (blob !is null && player !is null)
	{
		ConfigFile stats;
		if (stats.loadFile("../Cache/" + g_statsFile))
		{
			stats.add_u32(player.getUsername(), 0);
			stats.saveFile(g_statsFile);
		}
	}
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	// end game when all red dead

	if (getNet().isServer())
	{
		// count red remaining

		if (blob.getTeamNum() == 1)
		{
			int redsCount = 0;
			CBlob@[] reds;
			if (getBlobsByTag("player", @reds))
			{
				for (uint i = 0; i < reds.length; i++)
				{
					CBlob@ red = reds[i];
					if (!red.hasTag("dead") && red.getTeamNum() != 0)
					{
						redsCount++;
					}
				}
			}

			// mark kill

			CPlayer@ dmgPlayer = blob.getPlayerOfRecentDamage();
			if (dmgPlayer !is null)
			{
				ConfigFile stats;
				if (stats.loadFile("../Cache/" + g_statsFile))
				{
					Stats_Mark_Kill(stats, dmgPlayer.getUsername());
					stats.saveFile(g_statsFile);
				}
			}

			// endgame?

			if (redsCount == 0)
			{
				DefaultWin(this);

				// sync stats

				ConfigFile stats;
				if (stats.loadFile("../Cache/" + g_statsFile))
				{
					const u32 currentTime = Stats_getCurrentTime(this);

					// note player names
					CBlob@[] players;
					if (getBlobsByTag("player", @players))
					{
						for (uint i = 0; i < players.length; i++)
						{
							CBlob@ player = players[i];
							if (player.getPlayer() !is null)
							{
								const string name = player.getPlayer().getUsername();
								Stats_Mark_TeamName(stats, name);
							}
						}
					}

					// note time
					Stats_Mark_TeamTimes(stats, currentTime);

					stats.saveFile(g_statsFile);
				}
			}
		}

		return;
	}

}

// render

void onRender(CRules@ this)
{
	Stats_Draw(this);
}
