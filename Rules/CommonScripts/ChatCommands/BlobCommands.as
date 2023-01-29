#include "ChatCommand.as"
#include "MakeSeed.as";
#include "MakeCrate.as";
#include "MakeScroll.as"

class TreeCommand : BlobCommand
{
	string[] treeTypes = { "pine", "bushy" };

	TreeCommand()
	{
		super("tree", "Spawn a tree seed");
		AddAlias("seed");
		SetUsage("[type]");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		string tree = "tree_" + treeTypes[0];

		if (args.size() > 0)
		{
			string type = args[0].toLower();
			if (treeTypes.find(type) == -1)
			{
				server_AddToChat(getTranslatedString("Specify a valid tree type: " + join(treeTypes, ", ")), ConsoleColour::ERROR, player);
				return;
			}

			tree = "tree_" + type;
		}

		server_MakeSeed(pos, tree);
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
		string description = args.size() > 0 ? join(args, " ") : blobName;

		if (isBlobBlacklisted(blobName, player))
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

		if (isBlobBlacklisted(blobName, player))
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
