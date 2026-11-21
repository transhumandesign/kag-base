// DummyCommon.as

namespace Dummy
{
	enum Type
	{
		OBSTRUCTOR_BACKGROUND = 260,
		OBSTRUCTOR
	};
}

bool isDummyTile(const TileType &in TILE)
{
	return TILE >= Dummy::OBSTRUCTOR_BACKGROUND && TILE <= Dummy::OBSTRUCTOR;
}
