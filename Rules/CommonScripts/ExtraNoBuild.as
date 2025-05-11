// ExtraNoBuild.as

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	CMap@ map = getMap();
	if (map is null)
	{
		error(" ExtraNoBuild.as, map is null ");
		return;
	}

	const u16 mapWidth = map.tilemapwidth * map.tilesize;
	const u16 mapHeight = map.tilemapheight * map.tilesize;
	const u8 barrierWidth = 2 * map.tilesize;
	const u8 barrierHeight = 3 * map.tilesize;

	// Ceiling
	Vec2f tlCeiling = Vec2f_zero;
	Vec2f brCeiling = Vec2f(mapWidth, barrierHeight);
	map.server_AddSector(tlCeiling, brCeiling, "no build");

	// Prevents any solid blocks
	brCeiling.y += barrierHeight;
    map.server_AddSector(tlCeiling, brCeiling, "no solids");

	// Prevents any blobs
    brCeiling.y += map.tilesize;
    map.server_AddSector(tlCeiling, brCeiling, "no blobs");

	// Left
	Vec2f tlLeft = Vec2f(0.0f, barrierHeight);
	Vec2f brLeft = Vec2f(barrierWidth, mapHeight);
	map.server_AddSector(tlLeft, brLeft, "no build");

	// Right
	Vec2f tlRight = Vec2f(mapWidth - barrierWidth, barrierHeight);
	Vec2f brRight = Vec2f(mapWidth, mapHeight);
	map.server_AddSector(tlRight, brRight, "no build");
}