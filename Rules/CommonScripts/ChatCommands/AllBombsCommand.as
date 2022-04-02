#include "ChatCommand.as"

class AllBombsCommand : ChatCommand
{
	AllBombsCommand()
	{
		super("allbombs", "Spawn all types of bombs");
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			for (uint i = 0; i < 2; i++)
			{
				server_CreateBlob("mat_bombs", -1, pos);
			}
			server_CreateBlob("mat_waterbombs", -1, pos);
		}
		else
		{
			server_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR, player);
		}
	}
}
