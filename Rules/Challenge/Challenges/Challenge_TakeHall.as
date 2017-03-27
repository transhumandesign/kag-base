#include "ChallengesCommon.as"

void onInit(CMap@ this)
{
	CRules@ rules = getRules();
	SetIntroduction(rules, "Take the Hall");

	if (getNet().isServer())
	{
		rules.set_bool("repeat if dead", true);

		// make stats file
		Stats_MakeFile(rules, "takehall");
		ConfigFile stats;
		if (!stats.loadFile("../Cache/" + g_statsFile))
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

void onBlobChangeTeam(CRules@ this, CBlob@ blob, const int oldTeam)
{
	if (blob.getName() == "hall" && oldTeam == 1)
	{
		DefaultWin(this);

		// sync stats

		if (!syncedStats)
		{
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
	CBlob@[] halls;
	if (getBlobsByName("hall", @halls))
	{
		for (uint step = 0; step < halls.length; ++step)
		{
			CBlob@ hall = halls[step];
			{
				Vec2f pos2d = getDriver().getScreenPosFromWorldPos(hall.getPosition());
				pos2d.x -= 28.0f;
				pos2d.y -= 92.0f + 16.0f * Maths::Sin(getGameTime() / 4.5f);
				GUI::DrawIconByName("$DEFEND_THIS$",  pos2d);
			}
		}
	}

	Stats_Draw(this);
}
