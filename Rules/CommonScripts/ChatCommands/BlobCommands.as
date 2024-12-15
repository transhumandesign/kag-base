#include "ChatCommand.as"
#include "MakeSeed.as";
#include "MakeCrate.as";
#include "MakeScroll.as";
#include "WAR_Technology.as";

class SeedCommand : BlobCommand
{
	string[] seedTypes = { "tree_pine", "tree_bushy", "grain_plant", "flowers", "bush"};

	SeedCommand()
	{
		super("seed", "Spawn a seed");
		SetUsage("[type]");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		string seed = seedTypes[XORRandom(seedTypes.size())];

		if (args.size() > 0)
		{
			string type = args[0].toLower();
			if (seedTypes.find(type) == -1)
			{
				server_AddToChat(getTranslatedString("Specify a valid seed type: " + join(seedTypes, ", ")), ConsoleColour::ERROR, player);
				return;
			}

			seed = type;
		}

		server_MakeSeed(pos, seed);
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
		// setting up scrolls if necessary
		if (!getRules().exists("all scrolls"))
		{
			SetupScrolls(getRules());
		}

		// no name specified, spawn a random scroll
		if (args.size() == 0)
		{
			ScrollSet@ allScrolls = getScrollSet("all scrolls");
			
			if (allScrolls !is null)
			{
				string[] scrolls_list = allScrolls.names;
				int scrolls_list_size = scrolls_list.size();
				
				if (scrolls_list_size > 0)
				{
					server_MakePredefinedScroll(pos, scrolls_list[XORRandom(scrolls_list_size)]);
				}
			}
			return;
		}

		// attempting to spawn scroll by name
		string scrollName = join(args, " ");
				
		CBlob@ scroll = server_MakePredefinedScroll(pos, scrollName);
		
		if (scroll is null)
		{
			server_AddToChat(getTranslatedString("Specify a valid scroll name:"), ConsoleColour::ERROR, player);
			
			ScrollSet@ allScrolls = getScrollSet("all scrolls");
			
			if (allScrolls !is null)
			{
				string[] scrolls_list = allScrolls.names;
				
				if (scrolls_list.size() > 0)
				{
					server_AddToChat(join(scrolls_list, ", "), ConsoleColour::ERROR, player);
				}
			}
			
			return;
		}
	}
}

class SpawnCommand : BlobCommand
{
	SpawnCommand()
	{
		super("spawn", "Spawn a blob");
		AddAlias("blob");
		AddAlias("s");
		SetUsage("<blob> (count)");
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

		int count = args.size() >= 2 ? parseInt(args[1]) : 1;

		if (count <= 0 || count > 100)
		{
			server_AddToChat(getTranslatedString("Invalid number of blobs to spawn: {COUNT}").replace("{COUNT}", ""+count), ConsoleColour::ERROR, player);
			return;
		}

		if (count != 1 && (player is null || !player.isMod()))
		{
			server_AddToChat(getTranslatedString("You are not allowed to spawn more than one blob at once"), ConsoleColour::ERROR, player);
			return;
		}

		u8 team = player.getBlob().getTeamNum();

		for (int i = 0; i < count; ++i)
		{
			CBlob@ newBlob = server_CreateBlob(blobName, team, Vec2f_zero);

			//invalid blobs will have 'broken' names
			if (newBlob is null || newBlob.getName() != blobName)
			{
				server_AddToChat(getTranslatedString("Blob '{BLOB}' not found").replace("{BLOB}", blobName), ConsoleColour::ERROR, player);
			}
			else
			{
				// setting blob spawn position based on blob's height
				f32 height = newBlob.getHeight();
				Vec2f spawnPos = pos + Vec2f(0, getMap().tilesize) - Vec2f(0, height/2);
				newBlob.setPosition(spawnPos);
			}
		}
	}
}
