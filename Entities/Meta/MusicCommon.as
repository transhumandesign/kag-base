bool isUnderground(Vec2f pos, CMap@ map)
{
	u8 ts = map.tilesize;
	return (map.getTile(pos).dirt > 0 &&
		map.getTile(pos + Vec2f(-ts, -ts)).dirt > 0 &&
		map.getTile(pos + Vec2f(ts, -ts)).dirt > 0 &&
		map.getTile(pos + Vec2f(-ts, ts)).dirt > 0 &&
		map.getTile(pos + Vec2f(ts, ts)).dirt > 0);
}

bool isNearWater(Vec2f pos, CMap@ map)
{
	u8 ts = map.tilesize;
	return (map.isInWater(pos + Vec2f(-ts * 3, ts * 2)) ||
		map.isInWater(pos + Vec2f(ts * 3, ts * 2)) ||
	map.isInWater(pos + Vec2f(-ts * 3, ts)) ||
	map.isInWater(pos + Vec2f(ts * 3, ts)) ||	
	map.isInWater(pos + Vec2f(ts * 3, 0.0f)) ||
	map.isInWater(pos + Vec2f(ts * 3, 0.0f)));
}

bool isUnderwater(CBlob@ blob, Vec2f pos, CMap@ map)
{
	return blob !is null && map.isInWater(pos) && map.isInWater(pos + Vec2f(0.0f, -blob.getRadius() * 0.66f));
}

bool isSky(Vec2f pos, CMap@ map)
{
	return pos.y < map.tilemapheight * map.tilesize * 0.2f;
}

bool isNight(CMap@ map)
{
	return map.getDayTime() > 0.75f;
}
