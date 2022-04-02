#include "ChatCommand.as"

class ArrowsCommand : ChatCommand
{
	ArrowsCommand()
	{
		super("arrows", "Spawn arrows");
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			for (uint i = 0; i < 3; i++)
			{
				server_CreateBlob("mat_arrows", -1, pos);
			}
		}
		else
		{
			server_AddToChat("Blobs cannot be spawned while dead or spectating", ConsoleColour::ERROR, player);
		}
	}
}
