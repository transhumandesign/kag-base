// TEMP!

#define SERVER_ONLY

void onTick(CRules@ this)
{
	if (!sv_test) // only works localhost only
	{
		return;
	}

	CPlayer@ p = getLocalPlayer();
	CMap@ map = getMap();
	if (p !is null && p.isMod())
	{
		// delete blob
		CControl@ c = getControls();
		if(c is null) return;

		if (c.isKeyJustPressed(KEY_KEY_X))
		{
			Vec2f pos = getBottomOfCursor(getControls().getMouseWorldPos());
			CBlob@ behindBlob = getMap().getBlobAtPosition(pos);

			if (behindBlob !is null)
			{
				behindBlob.server_Die();
			}
			else
			{
				map.server_SetTile(pos, CMap::tile_empty);
			}
		}
		if (c.isKeyJustPressed(KEY_KEY_Z))
		{
			Vec2f pos = getBottomOfCursor(getControls().getMouseWorldPos());
			map.server_SetTile(pos, CMap::tile_castle);
		}
	}
}


Vec2f getBottomOfCursor(Vec2f cursorPos)
{
	cursorPos = getMap().getTileSpacePosition(cursorPos);
	cursorPos = getMap().getTileWorldPosition(cursorPos);
	// check at bottom of cursor
	f32 w = getMap().tilesize / 2.0f;
	f32 h = getMap().tilesize / 2.0f;
	int offsetY = Maths::Max(1, Maths::Round(8 / getMap().tilesize)) - 1;
	h -= offsetY * getMap().tilesize / 2.0f;
	return Vec2f(cursorPos.x + w, cursorPos.y + h);
}

CBlob@ PlaceBlock(string name, bool static = false)
{
	Vec2f pos = getBottomOfCursor(getControls().getMouseWorldPos());

	// if (getMap().isBuildableAtPos( pos, 256, true ))
	{
		//CBlob@ behindBlob = getMap().getBlobAtPosition( pos );

		//if (behindBlob !is null)
		//{
		//    behindBlob.server_Die();
		//    return null;
		//}

		CBlob @block = server_CreateBlob(name);
		block.setPosition(pos);
		block.getShape().SetStatic(static);
		//block.SetFacingLeft( true );
		Sound::Play("Sounds/thud.ogg");
		return block;
	}
}