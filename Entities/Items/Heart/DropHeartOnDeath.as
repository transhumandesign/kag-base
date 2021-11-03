
//random heart on death (default is 100% of the time for consistency + to reward murder)

#define SERVER_ONLY

const u32 NEW_AGE = 14;

const f32 probability = 1.0f; //between 0 and 1

void dropHeart(CBlob@ this)
{
	if (!this.hasTag("dropped heart")) //double check
	{
		CPlayer@ killer = this.getPlayerOfRecentDamage();
		CPlayer@ myplayer = this.getDamageOwnerPlayer();

		if (killer is null || myplayer is null || killer.getUsername() == myplayer.getUsername()) { return; }

		// newb handicap - dont drop hearts from newbs
		bool newVictim = Time_DaysSince(myplayer.getRegistrationTime()) <= NEW_AGE;
		bool newKiller = Time_DaysSince(killer.getRegistrationTime()) <= NEW_AGE;
		if (newVictim && !newKiller) { return; }

		this.Tag("dropped heart");

		if ((XORRandom(1024) / 1024.0f) < probability)
		{
			CBlob@ heart = server_CreateBlob("heart", -1, this.getPosition());

			if (heart !is null)
			{
				Vec2f vel(XORRandom(2) == 0 ? -2.0 : 2.0f, -5.0f);
				heart.setVelocity(vel);
				heart.set_u16("healer", killer.getNetworkID());
			}
		}
	}
}

void onDie(CBlob@ this)
{
	if (this.hasTag("switch class") || this.hasTag("dropped heart") || this.hasBlob("food", 1)) { return; }    //don't make a heart on change class, or if this has already run before or if had bread

	dropHeart(this);
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
