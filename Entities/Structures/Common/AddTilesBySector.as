void AddTilesBySector(Vec2f ul, Vec2f lr, string sectorName, TileType tile, TileType omitTile = 255, bool hasWindow = false)
{
	if (isServer())
	{
		CMap@ map = getMap();
		const f32 tilesize = map.tilesize;
		Vec2f tpos = ul;
		Vec2f tsize(map.tilesize, map.tilesize);
		Vec2f center = ul + (lr - ul - tsize) * 0.5f;
		while (tpos.x < lr.x)
		{
			while (tpos.y < lr.y)
			{
				if (map.getSectorAtPosition(tpos, sectorName) !is null 
					&& map.getTile(tpos).type != omitTile
					&& !(tpos == center && hasWindow))
				{
					map.server_SetTile(tpos, tile);
				}
				tpos.y += tilesize;
			}
			tpos.x += tilesize;
			tpos.y = ul.y;
		}
	}
}
