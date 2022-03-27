#include "ChatCommand.as"

class StoneCommand : ChatCommand
{
	StoneCommand()
	{
		super("stone", "Spawn stone.");
		AddAlias("stones");
		SetDebugOnly();
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			CBlob@ stone = server_CreateBlob("mat_stone", -1, pos);
			stone.server_SetQuantity(500);
		}
		else
		{
			server_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR, player);
		}
	}
}
