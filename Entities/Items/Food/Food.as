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
	// this.server_setTeamNum(0); // blue fishy like in sprite sheet

	this.getCurrentScript().runFlags |= Script::remove_after_this;
}

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;
	string foodOwner = "Owner: " + blob.get_string("owner");

	if (mouseOnBlob && getLocalPlayerBlob() !is null && blob.getTeamNum() == getLocalPlayerBlob().getTeamNum() && !blob.isInInventory())
	{
		GUI::SetFont("menu");
		GUI::DrawTextCentered(foodOwner, blob.getScreenPos() + Vec2f(0, -30), color_white);
	}
}