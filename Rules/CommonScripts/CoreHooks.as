
#include "RulesCore.as";

//Default Rules Core hooks - simple proxy
//Make sure you dont forget JoinCoreHooks! :)

#include "SwitchFromSpec.as"

//not server only so that all the players get this
void onInit(CRules@ this)
{
	sv_gravity = 9.81f;
	particles_gravity.y = 0.25f;
}

void onTick(CRules@ this)
{
	if (!getNet().isServer())
		return;

	RulesCore@ core;
	this.get("core", @core);

	if (core !is null)
	{
		core.Update();
	}
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (!getNet().isServer())
		return;

	RulesCore@ core;
	this.get("core", @core);

	if (core !is null)
	{
		core.onPlayerDie(victim, killer, customData);
	}
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
	if (!getNet().isServer())
		return;

	RulesCore@ core;
	this.get("core", @core);

	if (core !is null)
	{
		core.AddPlayerSpawn(player);
	}
}

void onPlayerRequestTeamChange(CRules@ this, CPlayer@ player, u8 newteam)
{
	if (!getNet().isServer())
		return;

	if (!CanSwitchFromSpec(this, player, newteam))
	{
		player.server_setTeamNum(this.getSpectatorTeamNum());
		return;
	}

	if (!this.get_bool("managed teams"))
	{
		RulesCore@ core;
		this.get("core", @core);

		if (core !is null)
		{
			core.AddPlayerSpawn(player);
		}
	}
}

void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (!getNet().isServer())
		return;

	RulesCore@ core;
	this.get("core", @core);

	if (core !is null)
	{
		core.onSetPlayer(blob, player);
	}
}
