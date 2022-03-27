#include "ChatCommand.as"

class WoodCommand : ChatCommand
{
	WoodCommand()
	{
		super("wood", "Spawn wood.");
		SetDebugOnly();
	}

	void Execute(string[] args, CPlayer@ player)
	{
		CBlob@ blob = player.getBlob();

		if (isServer() && blob !is null)
		{
			Vec2f pos = blob.getPosition();
			CBlob@ wood = server_CreateBlob("mat_wood", -1, pos);
			wood.server_SetQuantity(500);
		}

		if (player.isMyPlayer() && blob is null)
		{
			client_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR);
		}
	}
}
