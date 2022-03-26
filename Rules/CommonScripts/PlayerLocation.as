#include "PlayerLocationCommon.as"

void onTick(CRules@ this)
{
	if (!isClient())
	{
		for (uint i = 0; i < getPlayerCount(); i++)
		{
			CPlayer@ player = getPlayer(i);
			if (player !is null)
			{
				this.Sync(player.getNetworkID() + " country", true);
				this.Sync(player.getNetworkID() + " region", true);
				this.Sync(player.getNetworkID() + " code", true);
			}
		}
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if (isServer())
	{
		tcpr("<locate> " + player.getNetworkID() + " " + player.server_getIP());
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	this.set_string(player.getNetworkID() + " country", "");
	this.set_string(player.getNetworkID() + " region", "");
	this.set_string(player.getNetworkID() + " code", "");
}

void onTCPRConnect(CRules@ this)
{
	for (uint i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player !is null)
		{
			tcpr("<locate> " + player.getNetworkID() + " " + player.server_getIP());
		}
	}
}
