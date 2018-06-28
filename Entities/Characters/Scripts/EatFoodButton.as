#include "Knocked.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
}

bool canEat(CBlob@ this, CBlob@ blob)
{
	return blob.exists("eat sound");
}

bool Eat(CBlob@ this, CBlob@ blob)
{
	if (canEat(this, blob))
	{
		this.server_Pickup(blob);
		this.server_DetachFrom(blob);
		return true;
	}
	return false;
}


void onTick(CBlob@ this)
{
	if (
		getNet().isServer() &&
		this.isKeyJustPressed(key_eat) &&
		!isKnocked(this) &&
		this.getHealth() < this.getInitialHealth()
	) {
		CBlob @carried = this.getCarriedBlob();
		if (carried !is null && canEat(this, carried))
		{
			Eat(this, carried);
		}
		else // search in inv
		{
			CInventory@ inv = this.getInventory();
			for (int i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob @blob = inv.getItem(i);
				if (canEat(this, blob))
				{
					Eat(this, blob);
					return;
				}
			}
		}
	}
}
