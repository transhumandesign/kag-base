void getBarrierRect(CRules@ rules, Vec2f &out tl, Vec2f &out br)
{
    CMap@ map = getMap();
	const u16 x1 = rules.get_u16("barrier_x1");
	const u16 x2 = rules.get_u16("barrier_x2");
	const u16 middle = (x1 + x2) * 0.5f;

	tl = Vec2f(x1, -50 * map.tilesize);
	br = Vec2f(x2, map.tilemapheight * map.tilesize);
}

const bool shouldBarrier(CRules@ rules)
{
	return rules.isIntermission() || rules.isWarmup() || rules.isBarrier();
}
