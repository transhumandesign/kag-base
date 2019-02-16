const string heal_id = "heal command";

bool canEat(CBlob@ blob)
{
	return blob.exists("eat sound");
}

void Heal(CBlob@ this, CBlob@ food)
{
	bool exists = getBlobByNetworkID(food.getNetworkID()) !is null;
	if (getNet().isServer() && this.hasTag("player") && this.getHealth() < this.getInitialHealth() && !food.hasTag("healed") && exists)
	{
		CBitStream params;
		params.write_u16(this.getNetworkID());

		u8 heal_amount = 255; //in quarter hearts, 255 means full hp

		if (food.getName() == "heart")	    // HACK
		{
			heal_amount = 4; // full heart
		} else if (food.getName() == "apple")
		{
			heal_amount = 4; // full heart
		}

		params.write_u8(heal_amount);

		food.SendCommand(food.getCommandID(heal_id), params);

		food.Tag("healed");
	}
}
