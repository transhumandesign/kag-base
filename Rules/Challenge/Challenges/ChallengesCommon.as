// common functions for Challenge maps

string g_statsFile;
const string stats_tag = "challenge_stats";
bool syncedStats = false;
// end global vars

// Hook for map loader
void LoadMap()	// this isn't run on client!
{
	ChallengeCommonLoad();
}

//

void ChallengeCommonLoad()
{
	CRules@ rules = getRules();
	if (rules is null)
	{
		error("Something went wrong Rules is null");
	}

	SetConfig(rules);
	RegisterFileExtensionScript("Scripts/MapLoaders/LoadChallengePNG.as", "png");
	LoadMap(getMapInParenthesis());
}

void SetConfig(CRules@ rules)
{
	syncedStats = false;
	rules.set_string("rulesconfig", "test");
	rules.set_string("rulesconfig", CFileMatcher("/" + getMapName() + ".cfg").getFirst());
}

void AddRulesScript(CRules@ rules)
{
	CFileMatcher@ files = CFileMatcher("Challenge_");
	//files.printMatches();
	while (files.iterating())
	{
		const string filename = files.getCurrent();
		if (rules.RemoveScript(filename))
		{
			printf("Removing rules script " + filename);
		}
	}

	printf("Adding rules script: " + getCurrentScriptName());
	rules.AddScript(getCurrentScriptName());

	rules.set_bool("no research", true);
}

// put in onInit( CRules@ this ) or onInit( CMap@ this )
void SetIntroduction(CRules@ this, const string &in shortName)
{
	this.set_string("short name", shortName);
	this.set_string(stats_tag, "");
	this.set_s32("restart_rules_after_game_time", 30 * 7.0f); // no better place?
}

void DefaultWin(CRules@ this, const string endGameMsg = "You've won!")
{
	this.SetTeamWon(0);
	this.SetCurrentState(GAME_OVER);
	this.SetGlobalMessage(endGameMsg);
	sv_mapautocycle = true;
}



//// STATS STUFF

string getMapName()
{
	return getFilenameWithoutExtension(getFilenameWithoutPath(getMapInParenthesis()));
}

void Stats_MakeFile(CRules@ this, const string &in mode)
{
	CRules@ rules = getRules();
	g_statsFile = "Stats_Challenge/stats_" + mode + "_" + getMapName() + ".cfg";
	this.set_string("stats file", g_statsFile);
	printf("STATS FILE -> ../Cache/" + g_statsFile);
	this.set_string(stats_tag, "");
}

void Stats_Draw(CRules@ this)
{
	if (g_videorecording)
		return;

	//string shortName = this.get_string("short name" );
//	const f32 screenMiddle = getScreenWidth()/2.0f;
//	GUI::DrawText( "   " + shortName + "", Vec2f(screenMiddle-60.0f, 0.0f), Vec2f(screenMiddle+60.0f, 20.0f), color_black, true, true, true );

	string text;
	text = this.get_string(stats_tag);
	if (text.size() > 0)
	{
		GUI::SetFont("menu");
		GUI::DrawText(text, Vec2f(20, 20), Vec2f(300, 200), color_black, false, false, true);
	}
}

void Stats_Send(CRules@ this, string &in text)
{
	text += "\n\n";
	this.set_string(stats_tag, text);
	this.Sync(stats_tag, true);
}

string Stats_Begin_Output()
{
	return "              High scores\n\n\n";
}

u32 Stats_getCurrentTime(CRules@ this)
{
	const u32 gameTicksLeft = this.get_u32("game ticks left");
	const u32 gameTicksDuration = this.get_u32("game ticks duration");
	return gameTicksDuration - gameTicksLeft;
}

// stats: individual time

void Stats_Add_IndividualTimeMeasures(ConfigFile@ stats)
{
	stats.add_u32("fastest time", 99999999);
	stats.add_string("fastest time name", "N/A");
}

void Stats_Mark_IndividualTime(ConfigFile@ stats, const string &in playerName, const u32 currentTime)
{
	if (!stats.exists("fastest time"))
		return;

	const u32 fastestTime = stats.read_u32("fastest time");
	if (currentTime < fastestTime)
	{
		stats.add_u32("fastest time", currentTime);
		stats.add_string("fastest time name", playerName);
	}

	stats.add_u32(playerName, currentTime);
}

string Stats_Output_IndividualTimeMeasures(ConfigFile@ stats)
{
	if (!stats.exists("fastest time") || !stats.exists("fastest time name"))
		return "";

	const u32 fastestTime = stats.read_u32("fastest time");
	const string fastestTimeName = stats.read_string("fastest time name");
	string fastestTimeText = "" + formatFloat(float(fastestTime) / 30.0f, '0', 4, 2);
	if (fastestTime >= 99999999)
		fastestTimeText = "N/A";
	return "   Fastest individual time:     $RED$" + fastestTimeText + "s$RED$\n     " + fastestTimeName + "\n\n\n";
}

// stats: team time

void Stats_Add_TeamTimeMeasures(ConfigFile@ stats)
{
	stats.add_u32("fastest team", 99999999);
	stats.add_string("fastest team names", "N/A");
}

void Stats_Mark_TeamTimes(ConfigFile@ stats, const u32 currentTime)
{
	if (!stats.exists("fastest team"))
		return;

	const u32 fastestTeamTime = stats.read_u32("fastest team");
	if (currentTime < fastestTeamTime)
	{
		stats.add_u32("fastest team", currentTime);
	}
}

string Stats_Output_TeamTimeMeasures(ConfigFile@ stats, bool showIndividualNames = true)
{
	if (!stats.exists("fastest team") || !stats.exists("fastest team names"))
		return "";

	const u32 fastestTeam = stats.read_u32("fastest team");
	const string fastestTimeNames = stats.read_string("fastest team names");
	string fastestTimeText = "" + formatFloat(float(fastestTeam) / 30.0f, '0', 4, 2);
	string stat;
	//if (fastestTeam < 99999999)
	{
		//stat += "   Fastest team time:     $RED$" + fastestTimeText + "s$RED$\n     " + fastestTimeNames + "\n\n";

		if (showIndividualNames)
		{
			CBlob@[] players;
			if (getBlobsByTag("player", @players))
			{
				for (uint i = 0; i < players.length; i++)
				{
					CBlob@ player = players[i];
					if (player.getPlayer() !is null)
					{
						const string name = player.getPlayer().getUsername();
						const u32 fastestPlayerTime = stats.exists(name) ? stats.read_u32(name) : 99999999;
						stat += "   " + name + ":     $RED$" + formatFloat(float(fastestPlayerTime) / 30.0f, '0', 4, 2) + "s$RED$\n";
					}
				}
			}
		}
	}
	stat += "\n";
	return stat;
}

void Stats_Mark_TeamName(ConfigFile@ stats, const string &in playerName)
{
	//if (!stats.exists("fastest team names"))
	//	return;

	//if (playerName == "")
	//{
	//	stats.add_string("fastest team names", "" );
	//	return;
	//}

	//string names;
	//names += playerName + ", ";
	//stats.add_string("fastest team names", names );
}

// stats: individual kills

void Stats_Add_KillMeasures(ConfigFile@ stats)
{
	stats.add_u32("most kills", 0);
	stats.add_string("most kills name", "N/A");

}

void Stats_Mark_Kill(ConfigFile@ stats, const string &in playerName)
{
	if (!stats.exists("most kills"))
		return;

	u32 currentKills = stats.exists(playerName) ? stats.read_u32(playerName) : 0;
	const u32 mostKills = stats.read_u32("most kills");

	currentKills++;
	if (currentKills > mostKills)
	{
		stats.add_u32("most kills", currentKills);
		stats.add_string("most kills name", playerName);
	}

	stats.add_u32(playerName, currentKills);
}

string Stats_Output_KillMeasures(ConfigFile@ stats)
{
	if (!stats.exists("most kills") || !stats.exists("most kills name"))
		return "";

	const u32 mostKills = stats.read_u32("most kills");
	const string mostKillsName = stats.read_string("most kills name");

	string text;
	if (mostKills < 99999999 && mostKillsName != "N/A")
	{
		text += "   Most kills:     $RED$" + mostKills + "$RED$\n     " + mostKillsName + "\n\n";
	}

	CBlob@[] players;
	if (getBlobsByTag("player", @players))
	{
		for (uint i = 0; i < players.length; i++)
		{
			CBlob@ player = players[i];
			if (player.getPlayer() !is null)
			{
				const string name = player.getPlayer().getUsername();
				const u32 kills = stats.exists(name) ? stats.read_u32(name) : 99999999;
				if (kills < 99999999)
				{
					text += "   " + name + ":     $RED$" + kills + "$RED$\n";
				}
			}
		}
	}
	text += "\n";
	return text;
}