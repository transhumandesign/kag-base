#include "ChatCommand.as"

class BombsCommand : ChatCommand
{
	BombsCommand()
	{
		super("bombs", "Spawn bombs.");
		SetDebugOnly();
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		CBlob@ blob = player.getBlob();

		if (isServer() && blob !is null)
		{
			Vec2f pos = blob.getPosition();
			for (uint i = 0; i < 3; i++)
			{
				server_CreateBlob("mat_bombs", -1, pos);
			}
		}

		if (player.isMyPlayer() && blob is null)
		{
			client_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR);
		}
	}
}
