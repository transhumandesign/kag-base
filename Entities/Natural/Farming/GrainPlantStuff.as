bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onDie(CBlob@ this)
{
	if (getNet().isServer())
	{
		if (this.hasTag("has grain"))
		{
			for (int i = 1; i <= 1; i++)
			{
				CBlob@ grain = server_CreateBlob("grain", this.getTeamNum(), this.getPosition() + Vec2f(0, -12));
				if (grain !is null)
				{
					grain.setVelocity(Vec2f(XORRandom(5) - 2.5f, XORRandom(5) - 2.5f));
				}
			}
		}
	}
}

