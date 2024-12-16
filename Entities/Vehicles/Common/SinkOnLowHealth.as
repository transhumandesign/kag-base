const f32 FREQ = 90;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 0;	 // start without ticking
	this.addCommandID("start sink client");
	if (this.hasTag("sinking"))
		this.getCurrentScript().tickFrequency = FREQ;
}

void onTick(CBlob@ this)
{
	// sink on low health

	if (this.isInWater() && this.getHealth() < this.getInitialHealth() * 0.3f)
	{
		this.getShape().getConsts().buoyancy *= this.isOnGround() ? 0.6f : 0.87f;
		this.getShape().getConsts().transports = false;
		this.getShape().SetRotationsAllowed(true);
		if (this.getShape().getConsts().buoyancy < 0.5f)
		{
			this.server_Hit(this, this.getPosition(), Vec2f_zero, 1.5f, 0);  // self damage
		}
	}
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
//	printf("health boat " + this.getHealth() );
	if (isServer() && this.getHealth() < this.getInitialHealth() * 0.3f && !this.hasTag("sinking"))
	{
		this.getCurrentScript().tickFrequency = FREQ;
		this.Tag("sinking");
		this.Sync("sinking", true);
		this.SendCommand(this.getCommandID("start sink client"));
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("start sink client") && isClient())
	{
		this.getCurrentScript().tickFrequency = FREQ;
		this.getSprite().PlaySound("BoatSinking.ogg");
	}
}