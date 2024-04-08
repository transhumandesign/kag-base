// GenericComponent.as

#include "MechanismsCommon.as";

void onInit(CBlob@ this)
{
	this.Tag("no pickup");
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
			
			grid.setAll(
			component.x,                        // x
			component.y,                        // y
			0,									// input topology section 0
			0,									// output topology section 0
			0,									// input topology section 1
			0,									// output topology section 1
			0,                                  // information
			0,                                  // power
			0);                                 // id
		}

		this.set("component", null);
	}
}

/*
void onDie(CBlob@ this)
{
	if (!this.exists("component")) return;

	Component@ component = null;
	if (!this.get("component", @component)) return;
}
*/
