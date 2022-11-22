void onRender(CSprite@ this)
{
	CBlob@ b = this.getBlob();
	
	if (b is null) return;

	TreeVars@ vars;
	b.get("TreeVars", @vars);

	float ts = getMap().tilesize;	
	Vec2f pos = b.getPosition();
	
	// draw proximity check box
	Vec2f tl = Vec2f(pos.x - 5 * ts, pos.y - (2 + vars.height * 2) * ts);
	Vec2f tr = Vec2f(pos.x + 5 * ts, pos.y - (2 + vars.height * 2) * ts);
	Vec2f bl = Vec2f(pos.x - 5 * ts, pos.y + 1 * ts);
	Vec2f br = Vec2f(pos.x + 5 * ts, pos.y + 1 * ts);
	
	GUI::DrawLine(tl,tr, SColor(255,255,255,255));
	GUI::DrawLine(tl, bl, SColor(255,255,255,255));
	GUI::DrawLine(bl, br, SColor(255,255,255,255));
	GUI::DrawLine(br, tr, SColor(255,255,255,255));
	
	// draw leaf box
	u8 wiggly_leaf_count = b.get_u8("wiggly leaves count");
	for (u8 i = 1; i <= wiggly_leaf_count; i++)
	{
		if (!b.exists("wiggly leaf " + i))	break;
		
		string layerName = b.get_string("wiggly leaf " + i);
		CSpriteLayer@ layer = this.getSpriteLayer(layerName);
		if (layer !is null)
		{
			int w = layer.getFrameWidth();
			int h = layer.getFrameHeight();
			Vec2f pos = layer.getWorldTranslation();
			Vec2f tl_2 = Vec2f(pos.x - w/2, pos.y - h/2);
			Vec2f tr_2 = Vec2f(pos.x + w/2, pos.y - h/2);
			Vec2f bl_2 = Vec2f(pos.x - w/2, pos.y + h/2);
			Vec2f br_2 = Vec2f(pos.x + w/2, pos.y + h/2);
			
			GUI::DrawLine(tl_2, tr_2, SColor(255,255,255,0));
			GUI::DrawLine(tl_2, bl_2, SColor(255,255,255,0));
			GUI::DrawLine(bl_2, br_2, SColor(255,255,255,0));
			GUI::DrawLine(br_2, tr_2, SColor(255,255,255,0));
		}
	}
}