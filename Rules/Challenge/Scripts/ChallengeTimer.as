//Rules timer!

// Requires "game ticks left" set originally

void onRender(CRules@ this)
{
	if (!this.isMatchRunning()) return;

	const u32 gameTicksLeft = this.get_u32("game ticks left");

	if (gameTicksLeft > 0)
	{
		s32 timeToEnd = s32(gameTicksLeft) / 30;
		s32 secondsToEnd = timeToEnd % 60;
		s32 MinutesToEnd = timeToEnd / 60;
		string minutes = (MinutesToEnd < 10) ? "0" + MinutesToEnd : "" + MinutesToEnd;
		string seconds = (secondsToEnd < 10) ? "0" + secondsToEnd : "" + secondsToEnd;
		string time_message = getTranslatedString("Time left: {MIN}:{SEC}").replace("{MIN}", minutes).replace("{SEC}", seconds);
		drawRulesFont(time_message, color_white, Vec2f(10, 80), Vec2f(getScreenWidth() - 20, 120), true, false);
	}
}
