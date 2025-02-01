#define SERVER_ONLY

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	
	// put on ground based on shape's position
	CMap@ map = getMap();
	uint ts = map.tilesize;
	Vec2f pos = shape.getPosition();
	pos = Vec2f(Maths::Floor(pos.x / ts) * ts, Maths::Floor(pos.y / ts) * ts); // align to tiles

	u8 checked_times = 0;

	while (!map.isTileSolid(pos))
	{
		pos += Vec2f(0, ts);
	
		// left the map, die
		if (pos.y >= map.tilemapheight * ts || pos.y < 0)
		{
			this.server_Die();
			return;
		}
		
		// if checked 10 times, leave it be
		checked_times++;
		if (checked_times >= 10)
			break;
	}

	this.setPosition(Vec2f(pos.x, pos.y - shape.getHeight() / 2 - shape.getOffset().y));
}
