void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
}

bool Eat(CBlob@ this, CBlob@ blob)
{
	if (blob.exists("eat sound"))
	{
		this.server_Pickup(blob);
		this.server_DetachFrom(blob);
		return true;
	}
	return false;
}


void onTick(CBlob@ this)
{
	if (getNet().isServer() && this.isKeyJustPressed(key_taunts) && this.getHealth() < this.getInitialHealth())
	{
		CBlob @carried = this.getCarriedBlob();
		if (carried !is null)
		{
			Eat(this, carried);
		}
		else // search in inv
		{
			CInventory@ inv = this.getInventory();
			for (int i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob @blob = inv.getItem(i);
				if (Eat(this, blob))
					return;
			}
		}
	}
}
