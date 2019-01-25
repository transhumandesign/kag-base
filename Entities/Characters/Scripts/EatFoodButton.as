#include "Knocked.as"
#include "EatCommon.as";

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
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
		if (carried !is null && canEat(carried))
		{
			Heal(this, carried);
		}
		else // search in inv
		{
			CInventory@ inv = this.getInventory();
			for (int i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob @blob = inv.getItem(i);
				if (canEat(blob))
				{
					Heal(this, blob);
					return;
				}
			}
		}
	}
}
