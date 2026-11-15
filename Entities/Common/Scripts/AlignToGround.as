#define SERVER_ONLY

void onTick(CBlob@ this)
{
	// without this moving will fail
	if (getGameTime() < 5) {
		return;
	}

	CMap@ map = getMap();
	uint ts = map.tilesize;
	Vec2f init_pos = this.getPosition();
	Vec2f col_pos;
	
	if (map.rayCastSolid(init_pos, Vec2f(init_pos.x, map.tilemapheight * ts), col_pos)) {
		CShape@ shape = this.getShape();
		this.setPosition(Vec2f(col_pos.x, col_pos.y - shape.getHeight() / 2 - shape.getOffset().y));
	}

	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
