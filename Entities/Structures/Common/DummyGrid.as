// DummyGrid.as

#define SERVER_ONLY

#include "DummyCommon.as";

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	CMap@ map = getMap();
	const u32 GRID_SIZE = map.tilemapwidth * map.tilemapheight;

	array<u16> grid(GRID_SIZE, 0);
	this.set(Dummy::GRID, grid);
}