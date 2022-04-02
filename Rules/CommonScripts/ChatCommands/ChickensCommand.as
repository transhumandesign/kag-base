#include "ChatCommand.as"

class ChickensCommand : ChatCommand
{
	ChickensCommand()
	{
		super("chickens", "Spawn a flock of chickens");
		AddAlias("chickenflock");
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			for (uint i = 0; i < 6; i++)
			{
				server_CreateBlob("chicken", -1, pos);
			}
		}
		else
		{
			server_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR, player);
		}
	}
}
