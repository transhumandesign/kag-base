void onInit(CBlob@ this)
{
	this.Tag("ignore_saw");
	
	if (this.exists("food name"))
	{
		this.setInventoryName(this.get_string("food name"));
	}

	u8 index = 6;
	if (this.exists("food sprite"))
	{
		index = this.get_u8("food sprite");
	}

	this.getSprite().SetFrameIndex(index);
	this.SetInventoryIcon(this.getSprite().getConsts().filename, index, Vec2f(16, 16));

	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
