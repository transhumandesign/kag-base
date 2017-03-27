#include "ChallengesCommon.as"

void onInit(CMap@ this)
{
	CRules@ rules = getRules();
	SetIntroduction(rules, "Kill the Necromancer");

	if (getNet().isServer())
	{
		rules.set_bool("repeat if dead", true);

		// make stats file
		Stats_MakeFile(rules, "necromancer");
		ConfigFile stats;
		if (!stats"../Cache/" + (g_statsFile))
		{
			Stats_Add_TeamTimeMeasures(stats);

			stats.saveFile(g_statsFile);
		}
	}

	AddRulesScript(rules);
}

void onTick(CMap@ this)
{
	CRules@ rules = getRules();

	// server check

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
					output += Stats_Output_TeamTimeMeasures(stats);

					Stats_Send(rules, output);
				}
				syncedStats = true;
			}

			return;
		}
	}
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (blob.getName() == "necromancer")
	{
		DefaultWin(this);

		// sync stats

		if (!syncedStats)
		{
			ConfigFile stats;
			if (stats.loadFile("../Cache/" + g_statsFile))
			{
				const u32 currentTime = Stats_getCurrentTime(this);
				Stats_Mark_TeamName(stats, "");

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

				// output
				string output;
				output += Stats_Begin_Output();
				output += Stats_Output_TeamTimeMeasures(stats);

				Stats_Send(this, output);
			}
			syncedStats = true;
		}
	}
}

// render

void onRender(CRules@ this)
{
	Stats_Draw(this);
}
