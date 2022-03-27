#include "ChatCommand.as"

class TeamCommand : ChatCommand
{
	TeamCommand()
	{
		super("team", "Change your team");
		SetDebugOnly();
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			server_AddToChat("Team cannot be changed while dead or spectating", ConsoleColour::ERROR, player);
			return;
		}

		if (args.size() == 0)
		{
			server_AddToChat("Specify a team number to change to", ConsoleColour::ERROR, player);
			return;
		}

		int team = parseInt(args[0]);
		blob.server_setTeamNum(team);
	}
}
