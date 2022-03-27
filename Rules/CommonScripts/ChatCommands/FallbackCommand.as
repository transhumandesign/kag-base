#include "ChatCommand.as"

class FallbackCommand : ChatCommand
{
	FallbackCommand()
	{
		SetDebugOnly();
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			if (player.isMyPlayer())
			{
				client_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR);
			}
			return;
		}

		if (ChatCommands::isBlobBlacklisted(name))
		{
			if (player.isMyPlayer())
			{
				client_AddToChat("This blacklisted blob cannot be spawned", ConsoleColour::ERROR);
			}
			return;
		}

		if (isServer())
		{
			Vec2f pos = blob.getPosition();
			u8 team = blob.getTeamNum();
			CBlob@ newBlob = server_CreateBlob(name, team, pos + Vec2f(0, -5));

			//invalid blobs will have 'broken' names
			if (newBlob is null || newBlob.getName() != name)
			{
				//unable to detect invalid blob on client so send the error message from the server
				server_AddToChat("Blob '" + name + "' not found", ConsoleColour::ERROR, player);
			}
		}
	}
}
