// include this in gamemode.cfg rules for timers to work
#define ALWAYS_ONRELOAD
#include "Timers.as"

void onInit(CRules@ this)
{
}

void onTick(CRules@ this)
{
	Game::Timer@[]@ timers;
	this.get("timers", @timers);
	if (timers !is null)
	{
		for (uint i = 0; i < timers.length; i++)
		{
			Game::TimerUpdate(timers[i]);
			if (timers[i].endTime == 0)
			{
				timers.removeAt(i);
				i = 0;
			}
		}
	}
}

void onRender(CRules@ this)
{
	Game::Timer@[]@ timers;
	this.get("timers", @timers);
	if (timers !is null)
	{
		const u32 gametime = getGameTime();

		for (uint i = 0; i < timers.length; i++)
		{
			Game::Timer@ timer = timers[i];
			if (!timer.showTimer)
				continue;

			if (timer.endTime > 0 && timer.endTime > gametime)
			{
				const s32 ticksToEnd = s32(timer.endTime - gametime);
				const s32 timeToEnd = ticksToEnd / getTicksASecond();
				const s32 secondsToEnd = timeToEnd % 60;
				const s32 minutesToEnd = timeToEnd / 60;
				drawRulesFont("" + ((minutesToEnd < 10) ? "0" + minutesToEnd : "" + minutesToEnd) + ":" + ((secondsToEnd < 10) ? "0" + secondsToEnd : "" + secondsToEnd),
				              SColor(255, 255, 255, 255), Vec2f(10, 6), Vec2f(getScreenWidth() - 20, 30 + i * 10), true, false);
			}
		}
	}
}