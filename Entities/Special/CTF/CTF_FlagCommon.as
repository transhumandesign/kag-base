const string return_prop = "return time";
const u16 return_time = 600;

bool canPickupFlag(CBlob@ blob)
{
	bool pick = !blob.hasAttached();

	if (!pick)
	{
		CBlob@ carried = blob.getCarriedBlob();
		if (carried !is null)
		{
			pick = carried.hasTag("temp blob");
		}
		else
		{
			pick = true;
		}
	}

	return pick;
}

bool shouldFastReturn(CBlob@ this)
{
	const int team = this.getTeamNum();

	bool fast_return = false;
	CBlob@[] overlapping;
	if (this.getOverlapping(overlapping))
	{
		for(uint i = 0; i < overlapping.length; i++)
		{
			if (overlapping[i].getTeamNum() == team && overlapping[i].hasTag("player"))
			{
				fast_return = true;
				break;
			}
		}
	}
	
	return fast_return;
}
