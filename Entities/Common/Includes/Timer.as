//timing functions based in a blob's properties

//use this to create or reset timers
void timer_reset(CBlob@ this, string timername)
{
	this.set_s32("timer_" + timername, getGameTime());
}

s32 timer_get_difference(s32 timer_time)
{
	return getGameTime() - timer_time;
}

s32 timer_get_ticks_elapsed(CBlob@ this, string timername)
{
	return timer_get_difference(this.get_s32("timer_" + timername));
}

bool timer_is_past_ticks(CBlob@ this, string timername, s32 ticks)
{
	return (timer_get_ticks_elapsed(this, timername) >= ticks);
}

bool timer_is_exactly(CBlob@ this, string timername, s32 ticks)
{
	return (timer_get_ticks_elapsed(this, timername) == ticks);
}


//RULES version
void timer_reset(string timername)
{
	getRules().set_s32("timer_" + timername, getGameTime());
}

s32 timer_get_ticks_elapsed(string timername)
{
	return timer_get_difference(getRules().get_s32("timer_" + timername));
}

bool timer_is_past_ticks(string timername, s32 ticks)
{
	return (timer_get_ticks_elapsed(timername) >= ticks);
}

bool timer_is_exactly(string timername, s32 ticks)
{
	return (timer_get_ticks_elapsed(timername) == ticks);
}
