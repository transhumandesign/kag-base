#include "ChatCommand.as"

class ChickensCommand : BlobCommand
{
	ChickensCommand()
	{
		super("chickens", "Spawn a flock of chickens");
		AddAlias("chickenflock");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		for (uint i = 0; i < 6; i++)
		{
			server_CreateBlob("chicken", -1, pos);
		}
	}
}

class FishiesCommand : BlobCommand
{
	FishiesCommand()
	{
		super("fishies", "Spawn a school of fishies");
		AddAlias("fishyschool");
		AddAlias("fishys");
		AddAlias("fishes");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		for (uint i = 0; i < 6; i++)
		{
			server_CreateBlob("fishy", -1, pos);
		}
	}
}

class SharksCommand : BlobCommand
{
	SharksCommand()
	{
		super("sharks", "Spawn a shiver of sharks");
		AddAlias("sharkfrenzy");
		AddAlias("sharkpit");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		for (uint i = 0; i < 6; i++)
		{
			server_CreateBlob("shark", -1, pos);
		}
	}
}

class BisonCommand : BlobCommand
{
	BisonCommand()
	{
		//incorrect plural but avoids confusion and
		//is consistent with other animal commands
		super("bisons", "Spawn a herd of bison");
		AddAlias("bisonherd");
	}

	void SpawnBlobAt(Vec2f pos, string[] args, CPlayer@ player)
	{
		for (uint i = 0; i < 6; i++)
		{
			server_CreateBlob("bison", -1, pos);
		}
	}
}
