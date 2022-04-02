#include "ChatCommand.as"

class FishiesCommand : ChatCommand
{
	FishiesCommand()
	{
		super("fishies", "Spawn a school of fishies");
		AddAlias("fishyschool");
		AddAlias("fishys");
		AddAlias("fishes");
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
				server_CreateBlob("fishy", -1, pos);
			}
		}
		else
		{
			server_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR, player);
		}
	}
}
