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
		CBlob@ blob = player.getBlob();

		if (isServer() && blob !is null)
		{
			Vec2f pos = blob.getPosition();
			server_MakeSeed(pos, "tree_pine", 600, 1, 16);
		}

		if (player.isMyPlayer() && blob is null)
		{
			client_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR);
		}
	}
}
