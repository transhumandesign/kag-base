#include "ArcherCommon.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_not_onground;
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
	// don't interact with tree if grappling is pulling you
	ArcherInfo@ archer;
	if (this.get("archerInfo", @archer))
	{
		if (archer.grappling && archer.grapple_id != 0xffff)
		{
			return;
		}
	}

	// fall off tree if pressing down
	if (this.isKeyPressed(key_down))
	{
		return;
	}

	if (this.getMap().getSectorAtPosition(this.getPosition(), "tree") !is null)
	{
		this.getShape().getVars().onladder = true;

	}

}
