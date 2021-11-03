void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 60;
}

void onTick(CBlob@ this)
{
	CBlob@[] blobsInRadius;
	if (getMap().getBlobsInRadius(this.getPosition(), this.getRadius(), @blobsInRadius))
	{
		const u8 teamNum = this.getTeamNum();
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (this.getTeamNum() == teamNum && b.getHealth() < b.getInitialHealth() && b.hasTag("flesh") && !b.hasTag("dead"))
			{
				f32 oldHealth = b.getHealth();
				b.server_Heal(1.0f);
				b.add_f32("heal amount", b.getHealth() - oldHealth);
				b.getSprite().PlaySound("/Heart.ogg", 0.5);
			}
		}
	}
}
