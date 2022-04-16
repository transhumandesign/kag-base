#include "AbstractCommand.as"

class AllArrowsCommand : BlobCommand
{
	AllArrowsCommand()
	{
		super("allarrows", "Spawn all types of arrows");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		server_CreateBlob("mat_arrows", -1, pos);
		server_CreateBlob("mat_waterarrows", -1, pos);
		server_CreateBlob("mat_firearrows", -1, pos);
		server_CreateBlob("mat_bombarrows", -1, pos);
	}
}

class AllBombsCommand : ChatCommand
{
	AllBombsCommand()
	{
		super("allbombs", "Spawn all types of bombs");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		for (uint i = 0; i < 2; i++)
		{
			server_CreateBlob("mat_bombs", -1, pos);
		}
	}
}

class ArrowsCommand : ChatCommand
{
	ArrowsCommand()
	{
		super("arrows", "Spawn arrows");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		for (uint i = 0; i < 3; i++)
		{
			server_CreateBlob("mat_arrows", -1, pos);
		}
	}
}

class BombsCommand : ChatCommand
{
	BombsCommand()
	{
		super("bombs", "Spawn bombs");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		for (uint i = 0; i < 3; i++)
		{
			server_CreateBlob("mat_bombs", -1, pos);
		}
	}
}
