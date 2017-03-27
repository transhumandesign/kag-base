//Join and leave hooks for rulescore

#include "RulesCore.as"
#define SERVER_ONLY

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	RulesCore@ core;
	this.get("core", @core);

	if (core !is null)
	{
		core.AddPlayer(player);
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	RulesCore@ core;
	this.get("core", @core);

	if (core !is null)
	{
		core.RemovePlayer(player);
	}
}
