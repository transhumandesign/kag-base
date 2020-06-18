#include "ArcherCommon.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_not_onground;
	this.getCurrentScript().removeIfTag = "dead";

	this.set_u16("climbed_tree", 0);
}

void onTick(CBlob@ this)
{
	// don't interact with tree if grappling is pulling you
	/*ArcherInfo@ archer;
	if (this.get("archerInfo", @archer))
	{
		if (archer.grappling && archer.grapple_id != 0xffff)
		{
			this.set_u16("climbed_tree", 0);
			return;
		}
	}*/

	// fall off tree if pressing down
	if (this.isKeyPressed(key_down))
	{
		//this.set_u16("climbed_tree", 0);
		return;
	}

	CMap::Sector@ tree_sector = this.getMap().getSectorAtPosition(this.getPosition(), "tree");
	if (tree_sector !is null)
	{
		u16 climbed_tree_id = this.get_u16("climbed_tree");
		if (climbed_tree_id == tree_sector.ownerID)
		{
			this.getShape().getVars().onladder = true;
		}
		else if(this.isKeyPressed(key_up))
		{
			this.getShape().getVars().onladder = true;
			this.set_u16("climbed_tree", tree_sector.ownerID);
		}
		else
		{
			this.set_u16("climbed_tree", 0);
		}

	}
	else
	{
		this.set_u16("climbed_tree", 0);

	}

}
