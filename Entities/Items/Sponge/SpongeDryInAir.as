#include "SpongeCommon.as";

const int slow_frequency = 5; // don't run this script too often

#define SERVER

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 30 * 2 * slow_frequency; // 0.5 "absorbs" per seconds, run only every 5 "absorbs"
}

void onTick(CBlob@ this)
{
	u8 absorbed = this.get_u8(ABSORBED_PROP);
	absorbed = Maths::Max(0, absorbed - slow_frequency);
	this.set_u8(ABSORBED_PROP, absorbed);
	this.Sync(ABSORBED_PROP, true);
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.doTickScripts = true;
}

void onThisRemoveFromInventory( CBlob@ this, CBlob@ inventoryBlob )
{
	spongeUpdateSprite(this.getSprite(), this.get_u8(ABSORBED_PROP));
}