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
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			getMap().server_setFloodWaterWorldspace(pos, true);
		}
		else
		{
			server_AddToChat("Water cannot be created while dead or spectating", ConsoleColour::ERROR, player);
		}
	}
}
