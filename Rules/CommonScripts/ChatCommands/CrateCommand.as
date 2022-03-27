#include "ChatCommand.as"
#include "MakeCrate.as";

class CrateCommand : ChatCommand
{
	CrateCommand()
	{
		super("crate", "Spawn a crate with an optional blob inside.");
		SetDebugOnly();
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
