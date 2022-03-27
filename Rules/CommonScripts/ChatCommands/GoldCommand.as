#include "ChatCommand.as"

class GoldCommand : ChatCommand
{
	GoldCommand()
	{
		super("gold", "Spawn gold.");
		SetDebugOnly();
	}

	void Execute(string[] args, CPlayer@ player)
	{
		CBlob@ blob = player.getBlob();

		if (isServer() && blob !is null)
		{
			Vec2f pos = blob.getPosition();
			CBlob@ gold = server_CreateBlob("mat_gold", -1, pos);
			gold.server_SetQuantity(100);
		}

		if (player.isMyPlayer() && blob is null)
		{
			client_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR);
		}
	}
}
