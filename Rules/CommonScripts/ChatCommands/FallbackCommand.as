#include "ChatCommand.as"

class FallbackCommand : ChatCommand
{
	FallbackCommand()
	{
		super("<blob>", "Spawn a blob");
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

		if (isBlobBlacklisted(name))
		{
			server_AddToChat("This blacklisted blob cannot be spawned", ConsoleColour::ERROR, player);
			return;
		}

		Vec2f pos = blob.getPosition();
		u8 team = blob.getTeamNum();
		CBlob@ newBlob = server_CreateBlob(name, team, pos + Vec2f(0, -5));

		//invalid blobs will have 'broken' names
		if (newBlob is null || newBlob.getName() != name)
		{
			server_AddToChat("Blob '" + name + "' not found", ConsoleColour::ERROR, player);
		}
	}
}
