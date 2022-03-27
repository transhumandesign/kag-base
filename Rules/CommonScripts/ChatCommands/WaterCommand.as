#include "ChatCommand.as"

class WaterCommand : ChatCommand
{
	WaterCommand()
	{
		super("water", "Create a water source.");
		AddAlias("spawnwater");
		SetModOnly();
		SetDebugOnly();
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		CBlob@ blob = player.getBlob();

		if (isServer() && blob !is null)
		{
			Vec2f pos = blob.getPosition();
			getMap().server_setFloodWaterWorldspace(pos, true);
		}

		if (player.isMyPlayer() && blob is null)
		{
			client_AddToChat("Water cannot be created while dead or spectating", ConsoleColour::ERROR);
		}
	}
}
