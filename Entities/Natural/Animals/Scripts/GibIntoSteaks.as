
//gib into steak blob(s) on death

void onInit(CBlob@ this)
{
	if (!this.exists("number of steaks"))
		this.set_u8("number of steaks", 1);
}

void onDie(CBlob@ this)
{
	if (getNet().isServer() && this.getHealth() < 0.0f)
	{
		u8 steaks = this.get_u8("number of steaks");

		for (uint step = 0; step < steaks; ++step)
		{
			CBlob@ steak = server_CreateBlob("steak", -1, this.getPosition());
			if (steak !is null)
			{
				steak.setVelocity(Vec2f((XORRandom(16) - 8) * 0.5f, -2 - XORRandom(8) * 0.5f));
			}
		}
	}
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
