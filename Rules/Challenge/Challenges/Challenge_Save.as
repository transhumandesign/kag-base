#include "ChallengesCommon.as"

void onInit(CMap@ this)
{
	CRules@ rules = getRules();
	SetIntroduction(rules, "Save the Princess!");

	if (getNet().isServer())
	{
		rules.set_bool("repeat if dead", true);

		// make stats file
		Stats_MakeFile(rules, "save");
		ConfigFile stats;
		if (!stats.loadFile(g_statsFile))
		{
			Stats_Add_IndividualTimeMeasures(stats);

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
		CBlob@ princess;
		CBlob@[] blobs;
		if (getBlobsByName("princess", @blobs))
		{
			@princess = blobs[0];
			if (princess.hasTag("dead"))
				@princess = null;
		}

		CBlob@[] players;
		getBlobsByTag("player", @players);

		if (princess !is null)
		{
			for (uint i = 0; i < players.length; i++)
			{
				CBlob@ player = players[i];
				if (player.getTeamNum() == 0)
				{
					if ((princess.getPosition() - player.getPosition()).getLength() < 25.0f)
					{
						if (!rules.isGameOver())
						{
							rules.set_bool("played fanfare", true); //
							DefaultWin(rules);
							rules.SetGlobalMessage(getTranslatedString("You saved the princess!"));
						}

						ConfigFile stats;
						if (stats.loadFile(g_statsFile))
						{
							const u32 currentTime = Stats_getCurrentTime(rules);
							Stats_Mark_IndividualTime(stats, player.getPlayer().getUsername(), currentTime);
							stats.saveFile(g_statsFile);
						}
					}
				}
			}
		}
		else
		{
			rules.SetTeamWon(1);
			rules.SetCurrentState(GAME_OVER);
			rules.SetGlobalMessage(getTranslatedString("The princess died!"));
		}

		if (rules.isGameOver())
		{
			// sync stats

			if (!syncedStats)
			{
				ConfigFile stats;
				string output;
				if (stats.loadFile(g_statsFile))
				{
					output += Stats_Begin_Output();
					output += Stats_Output_IndividualTimeMeasures(stats);

					Stats_Send(rules, output);
				}
				syncedStats = true;
			}

			return;
		}
	}
}

// render

void onRender(CRules@ this)
{
	CBlob@[] princesses;
	if (getBlobsByName("princess", @princesses))
	{
		for (uint step = 0; step < princesses.length; ++step)
		{
			CBlob@ princess = princesses[step];
			{
				Vec2f pos2d = getDriver().getScreenPosFromWorldPos(princess.getPosition());
				pos2d.x -= 28.0f;
				pos2d.y -= 92.0f + 16.0f * Maths::Sin(getGameTime() / 4.5f);
				GUI::DrawIconByName("$DEFEND_THIS$",  pos2d);
			}
		}
	}

	Stats_Draw(this);
}
