#include "ArcherCommon.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_not_onground;
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{

	ArcherInfo@ archer;
	if (this.get("archerInfo", @archer))
	{
		if (archer.grappling && archer.grapple_id != 0xffff)
		{
			return;
		}
	}

	if (this.getMap().getSectorAtPosition(this.getPosition(), "tree") !is null)
	{
		this.getShape().getVars().onladder = true;

	}

}
