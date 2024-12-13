
#include "Hitters.as"

const string burn_duration = "burn duration";
const string burn_hitter = "burn hitter";
const string burn_timer = "burn timer";
const string burning_tag = "burning";
const string spread_fire_tag = "spread fire";
const string burn_counter = "burn counter";

const int fire_wait_ticks = 4;
const int burn_thresh = 70;

/**
 * Start this's fire and sync everything important
 */
void server_setFireOn(CBlob@ this)
{
	if (!getNet().isServer())
		return;
		
	this.Tag(burning_tag);
	this.Sync(burning_tag, true);

	this.set_s16(burn_timer, this.get_s16(burn_duration) / fire_wait_ticks);
	this.Sync(burn_timer, true);
}

/**
 * Put out this's fire and sync everything important
 */
void server_setFireOff(CBlob@ this)
{
	if (!getNet().isServer())
		return;
	this.Untag(burning_tag);
	this.Sync(burning_tag, true);

	this.set_s16(burn_timer, 0);
	this.Sync(burn_timer, true);
	
	this.set_s16(burn_counter, 0);
	this.Sync(burn_counter, true);
}

/**
 * Hitters that should start something burning when hit
 */
bool isIgniteHitter(u8 hitter)
{
	return hitter == Hitters::fire;
}
