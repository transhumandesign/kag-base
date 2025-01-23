//Rules timer!

// Requires game_end_time set originally

void onInit(CRules@ this)
{
	if (!this.exists("no timer"))
		this.set_bool("no timer", false);
	if (!this.exists("game_end_time"))
		this.set_u32("game_end_time", 0);
	if (!this.exists("end_in"))
		this.set_s32("end_in", 0);
	if (!this.exists("exclude_global_messages"))
		this.set_bool("exclude_global_messages", false);
}

void handleGlobalMessage(CRules@ this, string message, string messageToReplace = "", string replaceWith = "")
{
	if (this.get_bool("exclude_global_messages"))
	{
		return;
	}
	this.SetGlobalMessage(message);
	if (messageToReplace != "" && replaceWith != "")
	{
		this.AddGlobalMessageReplacement(messageToReplace, replaceWith);
	}
}

void onTick(CRules@ this)
{
	if (!getNet().isServer() || !this.isMatchRunning() || this.get_bool("no timer"))
	{
		return;
	}

	u32 gameEndTime = this.get_u32("game_end_time");

	if (gameEndTime == 0) return; //-------------------- early out if no time.

	this.set_s32("end_in", (s32(gameEndTime) - s32(getGameTime())) / 30);
	this.Sync("end_in", true);

	if (getGameTime() > gameEndTime)
	{
		bool hasWinner = false;
		s8 teamWonNumber = -1;

		if (this.exists("team_wins_on_end"))
		{
			teamWonNumber = this.get_s8("team_wins_on_end");
		}

		if (teamWonNumber >= 0)
		{
			//ends the game and sets the winning team
			this.SetTeamWon(teamWonNumber);
			CTeam@ teamWon = this.getTeam(teamWonNumber);

			if (teamWon !is null)
			{
				hasWinner = true;
				handleGlobalMessage(this, "Time is up!\n{WINNING_TEAM} wins the game!", "WINNING_TEAM", teamWon.getName());
			}
		}

		if (!hasWinner)
		{
			handleGlobalMessage(this, "Time is up!\nIt's a tie!");
		}
		
		// GAME_OVER
		this.SetCurrentState(3);
	}
}

void onRender(CRules@ this)
{
	if (g_videorecording)
		return;

	if (!this.isMatchRunning() || this.get_bool("no timer") || !this.exists("end_in")) return;

	s32 end_in = this.get_s32("end_in");

	if (end_in > 0)
	{
		s32 timeToEnd = end_in;

		s32 secondsToEnd = timeToEnd % 60;
		s32 MinutesToEnd = timeToEnd / 60;
		drawRulesFont(getTranslatedString("Time left: {MIN}:{SEC}")
						.replace("{MIN}", "" + ((MinutesToEnd < 10) ? "0" + MinutesToEnd : "" + MinutesToEnd))
						.replace("{SEC}", "" + ((secondsToEnd < 10) ? "0" + secondsToEnd : "" + secondsToEnd)),
		              SColor(255, 255, 255, 255), Vec2f(10, 128), Vec2f(getScreenWidth() - 20, 180), true, false);
	}
}
