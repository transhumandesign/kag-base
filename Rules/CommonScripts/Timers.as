namespace Game
{

	funcdef void TIMER_CALLBACK(Timer@);

	class Timer
	{
		string name;
		u32 endTime;
		TIMER_CALLBACK @endFunc;
		bool showTimer;
		CRules@ rules;
	};


	Timer@ CreateTimer(const string &in name, const f32 secs, TIMER_CALLBACK @endFunc, const bool showTimer = false)
	{
		CRules@ rules = getRules();

		Timer@[]@ timers;
		rules.get("timers", @timers);
		if (timers is null)
		{
			Timer@[] _timers;
			rules.set("timers", @_timers);
			rules.get("timers", @timers);
		}

		Timer@ pTimer = getTimer(name);
		if (pTimer is null)
		{
			// create new timer
			Timer timer;
			timers.push_back(timer);
			@pTimer = timers[timers.length - 1];
		}
		pTimer.name = name;
		pTimer.endTime = getGameTime() + secs * getTicksASecond();
		@pTimer.endFunc = endFunc;
		pTimer.showTimer = showTimer;
		@pTimer.rules = rules;
		return pTimer;
	}

	void TimerUpdate(Timer@ this)
	{
		if (this.endTime > 0 && this.endTime <= getGameTime())
		{
			this.endFunc(this);
			this.endTime = 0;
		}
	}

	Timer@ getTimer(const string &in name)
	{
		CRules@ rules = getRules();
		Timer@[]@ timers;
		rules.get("timers", @timers);
		if (timers !is null)
		{
			for (uint i = 0; i < timers.length; i++)
			{
				if (timers[i].name == name)
				{
					return timers[i];
				}
			}
		}
		return null;
	}

	void FireTimer(const string &in name)
	{
		Timer@ timer = getTimer(name);
		if (timer !is null)
		{
			timer.endFunc(timer);
			timer.endTime = 0;
		}
	}

	void ClearAllTimers()
	{
		CRules@ rules = getRules();
		Timer@[]@ timers;
		rules.get("timers", @timers);
		if (timers !is null)
		{
			for (uint i = 0; i < timers.length; i++)
			{
				timers[i].endTime = 0;
			}
		}
	}

	void ClearTimer(const string &in name)
	{
		CRules@ rules = getRules();
		Timer@[]@ timers;
		rules.get("timers", @timers);
		if (timers !is null)
		{
			for (uint i = 0; i < timers.length; i++)
			{
				if (timers[i].name == name)
					timers[i].endTime = 0;
			}
		}
	}
}
