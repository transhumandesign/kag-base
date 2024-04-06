
void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	
	// put on ground based on shape's position
	CMap@ map = getMap();
	uint ts = map.tilesize;
	Vec2f pos = shape.getPosition();
	pos = Vec2f(Maths::Floor(pos.x / ts) * ts, Maths::Floor(pos.y / ts) * ts); // align to tiles

	while (!map.isTileSolid(pos))
	{
		pos += Vec2f(0, ts);
	
		// left the map, die
		if (pos.y >= map.tilemapheight * ts || pos.y < 0)
		{
			this.server_Die();
			return;
		}
	}

	this.setPosition(Vec2f(pos.x, pos.y - shape.getHeight() / 2 - shape.getOffset().y));
}
