// Princess logic

void onInit(CBlob@ this)
{
	this.set_bool("love is in the air", false);
}

void onTick(CBlob@ this)
{
	if (isServer())
	{
		// in love?
		CBrain@ brain = this.getBrain();
		bool loveServer = (brain !is null && brain.getTarget() !is null);
		this.set_bool("love is in the air", loveServer);
		this.Sync("love is in the air", true);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (isClient() && blob !is null && blob.hasTag("player") && !this.hasTag("dead"))
	{
		this.getSprite().PlaySound("/Kiss.ogg");
	}
}
