// Next Map after ~X seconds of cool down

#define SERVER_ONLY

const int cooldown = 300;

void onRestart(CRules@ this)
{
	this.set_s32("restart_rules_after_game", getGameTime() + cooldown);
}

void onInit(CRules@ this)
{
	if (!this.exists("restart_rules_after_game_time"))
	{
		this.set_s32("restart_rules_after_game_time", cooldown);
	}
	onRestart(this);
}

void onTick(CRules@ this)
{
	if (this.isMatchRunning() && getGameTime() % 30 == 0)
	{
		this.set_s32("restart_rules_after_game", getGameTime() + this.get_s32("restart_rules_after_game_time"));
		return;
	}

	if (!this.isGameOver())   //do nothing if the match is not over
	{
		return;
	}

	s32 timeToEnd = this.get_s32("restart_rules_after_game") - getGameTime();

	if (timeToEnd <= 0)
	{
		LoadNextMap(); //crash here if no more maps... why? it should loop, no?
	}
}
