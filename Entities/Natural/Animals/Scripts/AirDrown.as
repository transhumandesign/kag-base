
#include "Hitters.as";

void onInit(CBlob@ this)
{
	if (!this.exists("airdrown_time"))
		this.set_s16("airdrown_time", 400);

	this.set_s16("airdrown_ticks", 0);

	this.getCurrentScript().tickFrequency = 15;
}

void onTick(CBlob@ this)
{
	if (this.hasTag("dead"))
	{
		this.getCurrentScript().runFlags |= Script::remove_after_this;
		return;
	}

	s16 airdrown_ticks 	= this.get_s16("airdrown_ticks");
	s16 airdrown_time 	= this.get_s16("airdrown_time");

	airdrown_ticks += this.getCurrentScript().tickFrequency * (this.isInWater() ? -1 : +1);
	airdrown_ticks = Maths::Max(airdrown_ticks, 0);

	if (airdrown_ticks >= airdrown_time)
	{
		this.server_Hit(this, this.getPosition(), Vec2f(0, 1), 1.0f, 0, true);
		this.server_SetHealth(0.0f);
		this.Tag("dead");
	}

	this.set_s16("airdrown_ticks", airdrown_ticks);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{

	if (customData == Hitters::water)
	{
		this.set_s16("airdrown_ticks", 0);
	}

	return damage;
}

/*
void onRender(CSprite@ this)
{
	CPlayer@ local = getLocalPlayer();
	CBlob@ blob = this.getBlob();

	if (blob is null)
		return;
	
	s16 airticks = blob.get_s16("airdrown_ticks");
	s16 airtime = blob.get_s16("airdrown_time");
	GUI::DrawText("airdrown ticks: " + airticks + "\nairdrown time: " + airtime, blob.getPosition(), SColor(255,255,255,255));	
}
*/