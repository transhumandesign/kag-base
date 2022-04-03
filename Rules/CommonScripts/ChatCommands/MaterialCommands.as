#include "ChatCommand.as"

class AllMatsCommand : ChatCommand
{
	AllMatsCommand()
	{
		super("allmats", "Spawn all types of materials");
		AddAlias("allmaterials");
		AddAlias("materials");
		AddAlias("mats");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			CBlob@ wood = server_CreateBlob("mat_wood", -1, pos);
			wood.server_SetQuantity(500);
			CBlob@ stone = server_CreateBlob("mat_stone", -1, pos);
			stone.server_SetQuantity(500);
			CBlob@ gold = server_CreateBlob("mat_gold", -1, pos);
			gold.server_SetQuantity(100);
		}
		else
		{
			server_AddToChat(getTranslatedString("Blobs cannot be spawned while dead or spectating"), ConsoleColour::ERROR, player);
		}
	}
}

class WoodCommand : ChatCommand
{
	WoodCommand()
	{
		super("wood", "Spawn wood");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			CBlob@ wood = server_CreateBlob("mat_wood", -1, pos);
			wood.server_SetQuantity(500);
		}
		else
		{
			server_AddToChat(getTranslatedString("Blobs cannot be spawned while dead or spectating"), ConsoleColour::ERROR, player);
		}
	}
}

class StoneCommand : ChatCommand
{
	StoneCommand()
	{
		super("stone", "Spawn stone");
		AddAlias("stones");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			CBlob@ stone = server_CreateBlob("mat_stone", -1, pos);
			stone.server_SetQuantity(500);
		}
		else
		{
			server_AddToChat(getTranslatedString("Blobs cannot be spawned while dead or spectating"), ConsoleColour::ERROR, player);
		}
	}
}

class GoldCommand : ChatCommand
{
	GoldCommand()
	{
		super("gold", "Spawn gold");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			CBlob@ gold = server_CreateBlob("mat_gold", -1, pos);
			gold.server_SetQuantity(100);
		}
		else
		{
			server_AddToChat(getTranslatedString("Blobs cannot be spawned while dead or spectating"), ConsoleColour::ERROR, player);
		}
	}
}
