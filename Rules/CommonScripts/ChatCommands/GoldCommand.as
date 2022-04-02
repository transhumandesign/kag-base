#include "ChatCommand.as"

class GoldCommand : ChatCommand
{
	GoldCommand()
	{
		super("gold", "Spawn gold");
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			CBlob@ gold = server_CreateBlob("mat_gold", -1, pos);
			gold.server_SetQuantity(100);
		}
		else
		{
			server_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR, player);
		}
	}
}
