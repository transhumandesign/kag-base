#include "ChatCommand.as"

class ArcherCommand : ChatCommand
{
	ArcherCommand()
	{
		super("archer", "Change class to Archer");
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

		if (blob.getName() == "archer")
		{
			server_AddToChat("Your class is already Archer", ConsoleColour::ERROR, player);
			return;
		}

		CBlob@ archer = server_CreateBlob("archer", blob.getTeamNum(), blob.getPosition());
		archer.server_SetPlayer(player);
		blob.server_Die();
	}
}
