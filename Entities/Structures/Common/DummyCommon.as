// DummyCommon.as

namespace Dummy
{
	const string TILE = "dummy_tile";
	const string GRID = "dummy_grid";

	enum Type
	{
		SOLID = 256,
		BACKGROUND,
		LADDER,
		PLATFORM,
		OBSTRUCTOR_BACKGROUND,
		OBSTRUCTOR,
		COUNT
	};
}

void server_setDummyGridNetworkID(const u32 &in OFFSET, const u16 &in NETWORK_ID)
{
	array<u16>@ grid;
	if (getRules().get(Dummy::GRID, @grid))
	{
		grid[OFFSET] = NETWORK_ID;
	}
}

u16 server_getDummyGridNetworkID(const u32 &in OFFSET)
{
	array<u16>@ grid;
	if (getRules().get(Dummy::GRID, @grid))
	{
		return grid[OFFSET];
	}
	return 0;
}

bool isDummyTile(const TileType &in TILE)
{
	return TILE >= Dummy::SOLID && TILE < Dummy::COUNT;
}