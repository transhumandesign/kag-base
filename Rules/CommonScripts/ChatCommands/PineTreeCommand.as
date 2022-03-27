#include "ChatCommand.as"
#include "MakeSeed.as";

class PineTreeCommand : ChatCommand
{
	PineTreeCommand()
	{
		super("tree", "Spawn a pine tree seed.");
		AddAlias("seed");
		AddAlias("ptree");
		AddAlias("pseed");
		AddAlias("pinetree");
		AddAlias("pineseed");
		SetDebugOnly();
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			server_MakeSeed(pos, "tree_pine", 600, 1, 16);
		}
		else
		{
			server_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR, player);
		}
	}
}
