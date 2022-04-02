#include "ChatCommand.as"
#include "MakeSeed.as";
#include "MakeCrate.as";
#include "MakeScroll.as"

class PineTreeCommand : ChatCommand
{
	PineTreeCommand()
	{
		super("pinetree", "Spawn a pine tree seed");
		AddAlias("pineseed");
		AddAlias("tree");
		AddAlias("seed");
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

class BushyTreeCommand : ChatCommand
{
	BushyTreeCommand()
	{
		super("bushytree", "Spawn a bushy tree seed");
		AddAlias("bushyseed");
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

class CrateCommand : ChatCommand
{
	CrateCommand()
	{
		super("crate", "Spawn a crate with an optional blob inside");
		SetUsage("[blob] [description]");
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			server_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR, player);
			return;
		}

		Vec2f pos = blob.getPosition();
		u8 team = blob.getTeamNum();

		if (args.size() == 0)
		{
			server_MakeCrate("", "", 0, team, pos);
			return;
		}

		string blobName = args[0];
		args.removeAt(0);

		//TODO: make description kids safe
		string description = join(args, " ");

		if (isBlobBlacklisted(blobName))
		{
			server_AddToChat("Crates cannot be spawned containing this blacklisted blob", ConsoleColour::ERROR, player);
			return;
		}

		//TODO: show correct crate icon for siege
		server_MakeCrate(blobName, description, 0, team, pos);
	}
}

class ScrollCommand : ChatCommand
{
	ScrollCommand()
	{
		super("scroll", "Spawn a scroll by name");
		SetUsage("<name>");
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			server_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR, player);
			return;
		}

		if (args.size() == 0)
		{
			server_AddToChat("Specify the name of a scroll to spawn", ConsoleColour::ERROR, player);
			return;
		}

		Vec2f pos = blob.getPosition();
		string scrollName = join(args, " ");
		server_MakePredefinedScroll(pos, scrollName);
	}
}

class SpawnCommand : ChatCommand
{
	SpawnCommand()
	{
		super("spawn", "Spawn a blob");
		AddAlias("blob");
		SetUsage("<blob>");
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			server_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR, player);
			return;
		}

		if (args.size() == 0)
		{
			server_AddToChat("Specify the name of a blob to spawn", ConsoleColour::ERROR, player);
			return;
		}

		string blobName = args[0];

		if (isBlobBlacklisted(blobName))
		{
			server_AddToChat("This blacklisted blob cannot be spawned", ConsoleColour::ERROR, player);
			return;
		}

		Vec2f pos = blob.getPosition();
		u8 team = blob.getTeamNum();
		CBlob@ newBlob = server_CreateBlob(blobName, team, pos + Vec2f(0, -5));

		//invalid blobs will have 'broken' names
		if (newBlob is null || newBlob.getName() != blobName)
		{
			server_AddToChat("Blob '" + blobName + "' not found", ConsoleColour::ERROR, player);
		}
	}
}
