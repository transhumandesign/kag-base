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

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;

	string healerName;

	if(!blob.exists("healer"))
	{
		healerName = "No owner";
	}
	else
	{
		u16 healerID = blob.get_u16("healer");
		CPlayer@ healer = getPlayerByNetworkId(healerID);
		if(healer !is null)
		{
			healerName = healer.getUsername(); 
		}
	}

	string foodOwnership = "Owner: " + healerName;

	if (mouseOnBlob && getLocalPlayerBlob() !is null && blob.getTeamNum() == getLocalPlayerBlob().getTeamNum() && !blob.isInInventory())
	{
		GUI::SetFont("menu");
		GUI::DrawTextCentered(foodOwnership, blob.getScreenPos() + Vec2f(0, -30), color_white);
	}
}
