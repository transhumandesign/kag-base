bool DetectTiles(Vec2f ul, Vec2f lr)
{
	CMap@ map = getMap();
	const f32 tilesize = map.tilesize;
	Vec2f tpos = ul;
	while (tpos.x < lr.x)
	{
		while (tpos.y < lr.y)
		{
			TileType t = map.getTile(tpos).type;
			if (t != CMap::tile_empty)
			{
				return true;
			}
			tpos.y += tilesize;
		}
		tpos.x += tilesize;
		tpos.y = ul.y;
	}
	return false;
}
