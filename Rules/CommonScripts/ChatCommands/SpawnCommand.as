#include "ChatCommand.as"

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
