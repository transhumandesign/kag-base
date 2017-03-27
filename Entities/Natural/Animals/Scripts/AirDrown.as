
#include "Hitters.as";

void onInit(CBlob@ this)
{
	if (!this.exists("airdrown_time"))
		this.set_s16("airdrown_time", 400);

	this.set_s16("airdrown_ticks", 0);

	this.getCurrentScript().runFlags |= Script::tick_not_inwater;
	this.getCurrentScript().tickFrequency = 15;
}

void onTick(CBlob@ this)
{
	s16 ticks = this.get_s16("airdrown_ticks");

	ticks += this.getCurrentScript().tickFrequency;
	s16 time = this.get_s16("airdrown_time");

	if (ticks >= time)
	{
		this.server_Hit(this, this.getPosition(), Vec2f(0, 1), 1.0f, 0, true);
		this.server_SetHealth(0.0f);
		this.Tag("dead");
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
	else
	{
		this.set_s16("airdrown_ticks", ticks);
	}

}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{

	if (customData == Hitters::water)
	{
		this.set_s16("airdrown_ticks", 0);
	}

	return damage;
}
