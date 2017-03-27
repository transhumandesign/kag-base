#include "MakeMat.as";

class HarvestBlobPair
{
	string name;
	f32 amount_wood;
	f32 amount_stone;
	HarvestBlobPair(string blobname, f32 wood, f32 stone)
	{
		name = blobname;
		amount_wood = wood;
		amount_stone = stone;
	}
};

HarvestBlobPair[] pairs =
{
	HarvestBlobPair("log", 20.0f, 0.0f),
	HarvestBlobPair("wooden_door", 5.0f, 0.0f),
	HarvestBlobPair("stone_door", 0.0f, 5.0f),
	HarvestBlobPair("trap_block", 0.0f, 2.5f),
};

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (!getNet().isServer() || hitBlob is null)
		return;
	// make wood from hitting certain blobs

	if (damage > 0.0f)
	{
		string name = hitBlob.getName();

		int wood = 0;
		int stone = 0;
		for (uint i = 0; i < pairs.length; i++)
		{
			if (pairs[i].name == name)
			{
				stone = pairs[i].amount_stone * damage;
				wood = pairs[i].amount_wood * damage;
				break;
			}
		}

		if (wood > 0)
		{
			MakeMat(this, worldPoint, "mat_wood", wood);
		}
		if (stone > 0)
		{
			MakeMat(this, worldPoint, "mat_stone", stone);
		}
	}
}
