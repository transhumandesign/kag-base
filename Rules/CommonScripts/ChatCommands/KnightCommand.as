#include "ChatCommand.as"

class KnightCommand : ChatCommand
{
	KnightCommand()
	{
		super("knight", "Change class to Knight");
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			server_AddToChat("Your class cannot be changed while dead or spectating", ConsoleColour::ERROR, player);
			return;
		}

		if (blob.getName() == "knight")
		{
			server_AddToChat("Your class is already Knight", ConsoleColour::ERROR, player);
			return;
		}

		CBlob@ knight = server_CreateBlob("knight", blob.getTeamNum(), blob.getPosition());
		knight.server_SetPlayer(player);
		blob.server_Die();
	}
}
