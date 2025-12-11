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
	this.server_setTeamNum(0); // blue fishy like in sprite sheet

	// add icon to be used when loading into catapult
	string iconName = "$" + this.getInventoryName() + "$";
	if (!GUI::hasIconName(iconName))
	{
		AddIconToken(iconName, this.getSprite().getConsts().filename, Vec2f(16, 16), index);
	}

	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
