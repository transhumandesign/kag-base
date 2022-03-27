#include "ChatCommand.as"

class AllMatsCommand : ChatCommand
{
	AllMatsCommand()
	{
		super("allmats", "Spawn all types of materials");
		AddAlias("allmaterials");
		AddAlias("materials");
		AddAlias("mats");
		SetDebugOnly();
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			CBlob@ wood = server_CreateBlob("mat_wood", -1, pos);
			wood.server_SetQuantity(500);
			CBlob@ stone = server_CreateBlob("mat_stone", -1, pos);
			stone.server_SetQuantity(500);
			CBlob@ gold = server_CreateBlob("mat_gold", -1, pos);
			gold.server_SetQuantity(100);
		}
		else
		{
			server_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR, player);
		}
	}
}
