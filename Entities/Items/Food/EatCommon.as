const string heal_id = "heal command";

bool canEat(CBlob@ blob)
{
	return blob.exists("eat sound");
}

// returns the healing amount of a certain food (in quarter hearts) or 0 for non-food
u8 getHealingAmount(CBlob@ food)
{
	if (!canEat(food))
	{
		return 0;
	}

	if (food.getName() == "heart")	    // HACK
	{
		return 4; // 1 heart
	}

	return 255; // full healing
}

void Heal(CBlob@ this, CBlob@ food)
{
	bool exists = getBlobByNetworkID(food.getNetworkID()) !is null;
	if (getNet().isServer() && this.hasTag("player") && this.getHealth() < this.getInitialHealth() && !food.hasTag("healed") && exists)
	{
		CBitStream params;
		params.write_u16(this.getNetworkID());
		params.write_u8(getHealingAmount(food));
		food.SendCommand(food.getCommandID(heal_id), params);

		food.Tag("healed");
	}
}

void setHealer(CBlob@ this, CBlob@ healer)
{
    CPlayer@ player = attached.getPlayer();
	
    if (isServer() && player !is null && (this.getTeamNum() != healer.getTeamNum() || !this.exists("healer")))
    {
        this.server_setTeamNum(healer.getTeamNum());
        this.set_u16("healer", player.getNetworkID());
        this.Sync("healer", true);
    }
}
