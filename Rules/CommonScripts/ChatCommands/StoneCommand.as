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
		CBlob@ blob = player.getBlob();

		if (isServer() && blob !is null)
		{
			Vec2f pos = blob.getPosition();
			CBlob@ stone = server_CreateBlob("mat_stone", -1, pos);
			stone.server_SetQuantity(500);
		}

		if (player.isMyPlayer() && blob is null)
		{
			client_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR);
		}
	}
}
