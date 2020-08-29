CPlayer@ getOwnerPlayer(CBlob@ this)
{
	if (this.exists("owner"))
	{
		u16 ownerID = this.get_u16("owner");
		return getPlayerByNetworkId(ownerID);
	}

	return null;
}

void SetOwner(CBlob@ this, CPlayer@ owner_player)
{
	if (isServer() && owner_player !is null && (this.getTeamNum() != owner_player.getTeamNum() || !this.exists("owner")))
	{
		this.server_setTeamNum(owner_player.getTeamNum());
		this.set_u16("owner", owner_player.getNetworkID());
		this.Sync("owner", true);
	}
}

void DrawOwnerText(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	Vec2f center = blob.getInterpolatedPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;
	
	CPlayer@ player = getOwnerPlayer(blob);
	string ownership = "Owner: " + ( player !is null ? player.getUsername() : "No owner" );

	if (mouseOnBlob && getLocalPlayerBlob() !is null && blob.getTeamNum() == getLocalPlayerBlob().getTeamNum() && !blob.isInInventory())
	{
		GUI::SetFont("menu");
		GUI::DrawTextCentered(ownership, blob.getScreenPos() + Vec2f(0, -30), color_white);
	}
}
