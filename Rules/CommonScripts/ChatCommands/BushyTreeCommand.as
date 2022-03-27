#include "ChatCommand.as"
#include "MakeSeed.as";

class BushyTreeCommand : ChatCommand
{
	BushyTreeCommand()
	{
		super("btree", "Spawn a bushy tree seed.");
		AddAlias("bseed");
		AddAlias("bushytree");
		AddAlias("bushyseed");
		SetDebugOnly();
	}

	void Execute(string[] args, CPlayer@ player)
	{
		CBlob@ blob = player.getBlob();

		if (isServer() && blob !is null)
		{
			Vec2f pos = blob.getPosition();
			server_MakeSeed(pos, "tree_bushy", 400, 2, 16);
		}

		if (player.isMyPlayer() && blob is null)
		{
			client_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR);
		}
	}
}
