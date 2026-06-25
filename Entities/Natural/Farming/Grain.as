void onInit(CBlob@ this)
{
	this.Tag("ignore_saw");
	
	if (isServer())
	{
		this.Tag("decay not moving");
		this.set_u16("decay time", 60);
	}

	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
