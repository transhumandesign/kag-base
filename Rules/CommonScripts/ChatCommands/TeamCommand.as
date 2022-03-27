#include "ChatCommand.as"

class TeamCommand : ChatCommand
{
	TeamCommand()
	{
		super("team", "Change your team.");
		SetDebugOnly();
	}

	void Execute(string[] args, CPlayer@ player)
	{
		CBlob@ blob = player.getBlob();

		if (blob is null)
		{
			if (player.isMyPlayer())
			{
				client_AddToChat("Team cannot be changed while dead or spectating", ConsoleColour::ERROR);
			}
			return;
		}

		if (args.size() == 0)
		{
			if (player.isMyPlayer())
			{
				client_AddToChat("Specify a team number to change to", ConsoleColour::ERROR);
			}
			return;
		}

		if (isServer())
		{
			int team = parseInt(args[0]);
			blob.server_setTeamNum(team);
		}
	}
}
