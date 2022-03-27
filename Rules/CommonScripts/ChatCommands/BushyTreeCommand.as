#include "ChatCommand.as"
#include "MakeSeed.as";

class BushyTreeCommand : ChatCommand
{
	BushyTreeCommand()
	{
		super("bushytree", "Spawn a bushy tree seed");
		AddAlias("bushyseed");
		AddAlias("btree");
		AddAlias("bseed");
		SetDebugOnly();
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			server_MakeSeed(pos, "tree_bushy", 400, 2, 16);
		}
		else
		{
			server_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR, player);
		}
	}
}
