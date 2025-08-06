//Burn and spread fire

#include "Hitters.as";
#include "FireCommon.as";

Random _r();

void onInit(CBlob@ this)
{
	this.getShape().getConsts().isFlammable = true;

	if (!this.exists(burn_duration))
		this.set_s16(burn_duration , 300);

	if (!this.exists(burn_timer))
		this.set_s16(burn_timer , 0);

	this.getCurrentScript().tickFrequency = fire_wait_ticks;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (
		isIgniteHitter(customData) ||		// Fire arrows
		(this.isOverlapping(hitterBlob) && hitterBlob.isInFlames() && !this.isInFlames())) 	// Flaming enemy
	{
		server_setFireOn(this);
		if (hitterBlob.getDamageOwnerPlayer() !is null){
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

void BurnRandomNear(Vec2f pos)
{
	Vec2f p = pos + Vec2f((_r.NextFloat() - 0.5f) * 16.0f, (_r.NextFloat() - 0.5f) * 16.0f);
	getMap().server_setFireWorldspace(p, true);
}

//ensure it spreads correctly for one-hit tiles etc
void onDie(CBlob@ this)
{
	if (this.hasTag(burning_tag) && this.hasTag(spread_fire_tag))
	{
		BurnRandomNear(this.getPosition());
	}
}

void onTick(CBlob@ this)
{
	if (!this.hasTag(burning_tag) && !this.isInFlames())
		return;

	//print("burn time: " + this.get_s16(burn_timer) + " burn_count: " + this.get_s16(burn_counter));

	Vec2f pos = this.getPosition();
	CMap@ map = this.getMap();
	if (map is null)
		return;

	s16 burn_time = this.get_s16(burn_timer);
	//check if we should be getting set on fire or put out
	if (burn_time < (burn_thresh / fire_wait_ticks) && this.isInFlames() && !this.hasTag("invincible"))
	{
		server_setFireOn(this);
		burn_time = this.get_s16(burn_timer);
	}

	//check if we're extinguished
	if (burn_time == 0 || this.isInWater() || map.isInWater(pos))
	{
		server_setFireOff(this);
		this.set_netid("burn starter blob", 0);
	}

	//burnination
	else if (burn_time > 0)
	{
		s16 burn_count = this.get_s16(burn_counter);
		burn_count++;
	
		//burninating the other tiles
		if ((burn_count % 8) == 0 && this.hasTag(spread_fire_tag))
		{
			BurnRandomNear(pos);
		}

		//burninating the actor
		if ((burn_count % 7) == 0)
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

			blob.server_Hit(this, pos, Vec2f(0, 0), 0.25, Hitters::fire, true);
		}

		//burninating the burning time
		burn_time--;

		//making sure to set values correctly
		this.set_s16(burn_timer, burn_time);
		this.set_s16(burn_counter, burn_count);
	}

	// (flax roof cottages!)
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return !this.hasTag(burning_tag);
}
