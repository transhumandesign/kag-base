#include "SpongeCommon.as";

const int slow_frequency = 5; // don't run this script too often

#define SERVER

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 30 * 2 * slow_frequency; // 0.5 "absorbs" per seconds, run only every 5 "absorbs"
}

void onTick(CBlob@ this)
{
	u8 absorbed_amount = this.get_u8(ABSORBED_PROP);
	u32 absorbed_time = this.get_u32(ABSORBED_TIME);

	if (absorbed_amount > 0 &&
		absorbed_time + 15 < getGameTime()) // did we not remove water in the last 15 ticks?
    {
        absorbed_amount = Maths::Max(0, absorbed_amount - slow_frequency);
        this.set_u8(ABSORBED_PROP, absorbed_amount);
        this.Sync(ABSORBED_PROP, true);
	}
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.doTickScripts = true;
}

void onThisRemoveFromInventory( CBlob@ this, CBlob@ inventoryBlob )
{
	spongeUpdateSprite(this.getSprite(), this.get_u8(ABSORBED_PROP));
}