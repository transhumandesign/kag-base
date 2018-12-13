void onInit(CBlob@ this)
{
	this.Tag("ignore_saw"); // food cannot be destroyed by a saw
	
	if (this.exists("food name"))
	{
		this.setInventoryName(this.get_string("food name")); // I.e., TTH food factories produce "Burgers," which are food blobs with the name and texture of burgers
	}

	u8 index = 6;
	if (this.exists("food sprite"))
	{
		index = this.get_u8("food sprite"); // i.e. use burger texture
	}
	index = 6;// HACK!
	// If you remove the above line, then what happens is that instead of showing the default burger sprite, it will show the cooked steak sprite. So do not remove!

	this.getSprite().SetFrameIndex(index);
	this.SetInventoryIcon(this.getSprite().getConsts().filename, index, Vec2f(16, 16));
	this.server_setTeamNum(0); // blue fishy like in Food.png sprite sheet - doesn't actually do anything besides changing the team color

	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
