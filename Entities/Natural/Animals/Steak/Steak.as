void onInit(CBlob@ this)
{
	this.set_u16("decay time", 60);
	this.getSprite().getVars().gibbed = true;
}

void onHealthChange(CBlob@ this, f32 health_old)
{
	if (this.getHealth() <= 0)
	{
		this.getSprite().getVars().gibbed = false;
		this.getSprite().Gib();
		this.server_Die();
	}
}
