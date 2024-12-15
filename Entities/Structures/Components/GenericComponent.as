// GenericComponent.as

#include "MechanismsCommon.as";

void onInit(CBlob@ this)
{
	this.Tag("builder always hit");
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic && this.exists("component"))
	{
		Component@ component = null;
		if (!this.get("component", @component)) return;

		if (isServer())
		{
			MapPowerGrid@ grid;
			if (!getRules().get("power grid", @grid)) return;

			grid.setAll(component.x, component.y, 0, 0, 0, 0, 0);
		}

		this.set("component", null);
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}
