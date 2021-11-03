// LootOnDeath.as

#include "LootCommon.as";

void onDie(CBlob@ this)
{
	if (getNet().isServer() && !this.exists(DROP))
	{
		server_CreateLoot(this, this.getPosition(), this.getTeamNum());
	}
}