#include "ChatCommand.as"

class ChickensCommand : ChatCommand
{
	ChickensCommand()
	{
		super("chickens", "Spawn a flock of chicken.");
		AddAlias("chickenflock");
		SetDebugOnly();
	}

	void Execute(string[] args, CPlayer@ player)
	{
		CBlob@ blob = player.getBlob();

		if (isServer() && blob !is null)
		{
			Vec2f pos = blob.getPosition();
			for (uint i = 0; i < 6; i++)
			{
				server_CreateBlob("chicken", -1, pos);
			}
		}

		if (player.isMyPlayer() && blob is null)
		{
			client_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR);
		}
	}
}
