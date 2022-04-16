#include "AbstractCommands.as"
#include "MakeSeed.as";
#include "MakeCrate.as";
#include "MakeScroll.as"

class PineTreeCommand : BlobCommand
{
	PineTreeCommand()
	{
		super("pinetree", "Spawn a pine tree seed");
		AddAlias("pineseed");
		AddAlias("tree");
		AddAlias("seed");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		server_MakeSeed(pos, "tree_pine", 600, 1, 16);
	}
}

class BushyTreeCommand : BlobCommand
{
	BushyTreeCommand()
	{
		super("bushytree", "Spawn a bushy tree seed");
		AddAlias("bushyseed");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		server_MakeSeed(pos, "tree_bushy", 400, 2, 16);
	}
}

class CrateCommand : BlobCommand
{
	CrateCommand()
	{
		super("crate", "Spawn a crate with an optional blob inside");
		SetUsage("[blob] [description]");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		u8 team = player.getBlob().getTeamNum();

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
			server_AddToChat(getTranslatedString("Crates cannot be spawned containing this blacklisted blob"), ConsoleColour::ERROR, player);
			return;
		}

		//TODO: show correct crate icon for siege
		server_MakeCrate(blobName, description, 0, team, pos);
	}
}

class ScrollCommand : BlobCommand
{
	ScrollCommand()
	{
		super("scroll", "Spawn a scroll by name");
		SetUsage("<name>");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		if (args.size() == 0)
		{
			server_AddToChat(getTranslatedString("Specify the name of a scroll to spawn"), ConsoleColour::ERROR, player);
			return;
		}

		string scrollName = join(args, " ");
		server_MakePredefinedScroll(pos, scrollName);
	}
}

class SpawnCommand : BlobCommand
{
	SpawnCommand()
	{
		super("spawn", "Spawn a blob");
		AddAlias("blob");
		SetUsage("<blob>");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		if (args.size() == 0)
		{
			server_AddToChat(getTranslatedString("Specify the name of a blob to spawn"), ConsoleColour::ERROR, player);
			return;
		}

		string blobName = args[0];

		if (isBlobBlacklisted(blobName))
		{
			server_AddToChat(getTranslatedString("This blacklisted blob cannot be spawned"), ConsoleColour::ERROR, player);
			return;
		}

		u8 team = player.getBlob().getTeamNum();
		CBlob@ newBlob = server_CreateBlob(blobName, team, pos + Vec2f(0, -5));

		//invalid blobs will have 'broken' names
		if (newBlob is null || newBlob.getName() != blobName)
		{
			server_AddToChat(getTranslatedString("Blob '{BLOB}' not found").replace("{BLOB}", blobName), ConsoleColour::ERROR, player);
		}
	}
}
