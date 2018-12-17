//Burn and spread fire

#include "Hitters.as";
#include "FireCommon.as";

Random _r();

const int fire_spread_ticks = 12;

void onInit(CBlob@ this)
{
	this.getShape().getConsts().isFlammable = true;

	if (!this.exists(burn_duration))
		this.set_s16(burn_duration , 300);
	if (!this.exists(burn_hitter))
		this.set_u8(burn_hitter, Hitters::burn);

	if (!this.exists(burn_timer))
		this.set_s16(burn_timer , 0);

	this.getCurrentScript().tickFrequency = fire_wait_ticks;
	this.getCurrentScript().runFlags |= Script::tick_infire;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if ((isIgniteHitter(customData) && damage > 0.0f) ||					 	   // Fire arrows
	        (this.isOverlapping(hitterBlob) &&
	         hitterBlob.isInFlames() && !this.isInFlames()))	   // Flaming enemy
	{
		server_setFireOn(this);
		if(hitterBlob.getDamageOwnerPlayer() !is null){
			this.set_netid("burn starter player", hitterBlob.getDamageOwnerPlayer().getNetworkID());
		}
	}

	if (isWaterHitter(customData))	  // buckets of water
	{
		if (this.hasTag(burning_tag))
		{
			this.getSprite().PlaySound("/ExtinguishFire.ogg");
		}
		server_setFireOff(this);
		this.set_netid("burn starter player", 0);
	}

	return damage;
}

void BurnNear(Vec2f pos)
{
	CMap@ map = getMap();
	if (map is null)
	{
		return;
	}
	map.server_setFireWorldspace(pos - Vec2f(map.tilesize, 0.0f), true); // left
	map.server_setFireWorldspace(pos + Vec2f(map.tilesize, 0.0f), true); // right
	map.server_setFireWorldspace(pos - Vec2f(0.0f, map.tilesize), true); // up
	map.server_setFireWorldspace(pos + Vec2f(0.0f, map.tilesize), true); // down
}

//ensure it spreads correctly for one-hit tiles etc
void onDie(CBlob@ this)
{
	if (this.hasTag(burning_tag) && this.hasTag(spread_fire_tag))
	{
		BurnNear(this.getPosition());
	}
}

void onTick(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	CMap@ map = this.getMap();
	if (map is null)
		return;

	s16 burn_time = this.get_s16(burn_timer);
	//check if we should be getting set on fire or put out
	if (burn_time < (burn_thresh / fire_wait_ticks) && this.isInFlames())
	{
		server_setFireOn(this);
		burn_time = this.get_s16(burn_timer);
	}

	//check if we're extinguished
	if (burn_time == 0 || this.isInWater())
	{
		server_setFireOff(this);
		this.set_netid("burn starter blob", 0);
	}

	//burnination
	else if (burn_time > 0)
	{
		//burninating the other tiles
		if ((burn_time % fire_spread_ticks) == 0 && this.hasTag(spread_fire_tag))
		{
			BurnNear(pos);
		}

		//burninating the actor
		if ((burn_time % 7) == 0)
		{
			uint16 netid = this.get_netid("burn starter player");
			CBlob@ blob = null;
			CPlayer@ player = null;
			if (netid != 0)
				@player = getPlayerByNetworkId(this.get_netid("burn starter player"));

			if (player !is null)
				@blob = player.getBlob();

			if (blob is null)
				@blob = this;

			blob.server_Hit(this, pos, Vec2f(0, 0), 0.25, this.get_u8(burn_hitter), true);
		}

		//burninating the burning time
		burn_time--;

		//and making sure it's set correctly!
		this.set_s16(burn_timer, burn_time);
	}

	// (flax roof cottages!)
}
