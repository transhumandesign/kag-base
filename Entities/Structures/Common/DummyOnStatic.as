// DummyOnStatic.as

#define SERVER_ONLY

#include "DummyCommon.as";

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (this.exists(Dummy::TILE))
	{
		const Vec2f POSITION = this.getPosition();

		CMap@ map = getMap();
		if (map !is null)
		{
			if (isStatic)
			{
				map.server_SetTile(POSITION, this.get_TileType(Dummy::TILE));
				server_setDummyGridNetworkID(map.getTileOffset(POSITION), this.getNetworkID());
			}
			else
			{
				map.server_SetTile(POSITION, CMap::tile_empty);
				server_setDummyGridNetworkID(map.getTileOffset(POSITION), 0);
			}
		}
	}
}