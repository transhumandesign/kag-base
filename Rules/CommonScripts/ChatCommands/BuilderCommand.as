#include "ChatCommand.as"

class BuilderCommand : ChatCommand
{
	BuilderCommand()
	{
		super("builder", "Change class to Builder");
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

		if (blob.getName() == "builder")
		{
			server_AddToChat("Your class is already Builder", ConsoleColour::ERROR, player);
			return;
		}

		CBlob@ builder = server_CreateBlob("builder", blob.getTeamNum(), blob.getPosition());
		builder.server_SetPlayer(player);
		blob.server_Die();
	}
}
