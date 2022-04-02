#include "ChatCommand.as"

class WoodCommand : ChatCommand
{
	WoodCommand()
	{
		super("wood", "Spawn wood");
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
		}
		else
		{
			server_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR, player);
		}
	}
}
