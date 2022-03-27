#include "ChatCommand.as"

class AllArrowsCommand : ChatCommand
{
	AllArrowsCommand()
	{
		super("allarrows", "Spawn all types of arrows.");
		SetDebugOnly();
	}

	void Execute(string[] args, CPlayer@ player)
	{
		CBlob@ blob = player.getBlob();

		if (isServer() && blob !is null)
		{
			Vec2f pos = blob.getPosition();
			server_CreateBlob("mat_arrows", -1, pos);
			server_CreateBlob("mat_waterarrows", -1, pos);
			server_CreateBlob("mat_firearrows", -1, pos);
			server_CreateBlob("mat_bombarrows", -1, pos);
		}

		if (player.isMyPlayer() && blob is null)
		{
			client_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR);
		}
	}
}
