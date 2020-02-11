//AddSectorOnTiles.as
// Add sectors onto an area, matched to specific types of tiles

//(the rectangle finding parts of this might be a good candidate to move
// to the engine, let me know if the speed boost would be useful to you!)

//can determine matching rectangles for a given array of offsets
//	- currently only does horizontal fitting for in-order offsets (wide, short rectangles)
//	- it could be expanded to do full rectangle fitting for a given
//	  set of offsets, but this is enough for the hall, which is the only thing
//	  that uses it currently.
void DetermineRect(array<u32>@ offsets, array<Vec2f>@ rects)
{
	if (offsets.length == 0) return;

	CMap@ map = getMap();

	u32 last_offset = offsets[0];
	offsets.removeAt(0);

	Vec2f tl = map.getTileWorldPosition(last_offset);
	Vec2f lr = tl + Vec2f(map.tilesize, map.tilesize);

	bool found_next = true;
	while(found_next && offsets.length > 0)
	{
		found_next = false;
		u32 next_offset = offsets[0];
		if (next_offset == last_offset + 1)
		{
			last_offset = next_offset;
			lr.x += map.tilesize;
			offsets.removeAt(0);
			//do not wrap around the edge of the map
			if (next_offset % map.tilemapwidth != 0)
			{
				found_next = true;
			}
		}
	}

	//todo: expand

	rects.push_back(tl);
	rects.push_back(lr);
}

//convert an array of offsets to an array of rectangles, given as sequential
//vec2fs in the order: top left position, bottom right position
array<Vec2f> OffsetsToRects(array<u32> offsets)
{
	array<Vec2f> ret;

	while(offsets.length > 0) {
		DetermineRect(offsets, ret);
	}

	return ret;
}

//Add a given sector onto all tiles given as offsets
void AddSectorOnOffsets(array<u32>@ offsets, string sectorName, u16 nid = 0)
{
	CMap@ map = getMap();
	array<Vec2f> rects = OffsetsToRects(offsets);
	for (int i = 0; i < rects.length; i += 2)
	{
		Vec2f ul = rects[i];
		Vec2f lr = rects[i+1];
		map.server_AddSector(ul, lr, sectorName, "", nid);
	}
}

//Add a given sector onto all solid tiles in an area
void AddSectorOnSolid(Vec2f ul, Vec2f lr, string sectorName, u16 nid = 0)
{
	CMap@ map = getMap();
	Vec2f dif = lr - ul;
	f32 ts = map.tilesize;
	array<u32> offsets;
	for (f32 y = 0; y < dif.y; y += ts)
	{
		for (f32 x = 0; x < dif.x; x += ts)
		{
			Vec2f pos = ul + Vec2f(x, y);
			u32 offset = map.getTileOffset(pos);
			if (map.isTileSolid(map.getTile(offset)))
			{
				offsets.push_back(offset);
			}
		}
	}
	AddSectorOnOffsets(offsets, sectorName, nid);
}

//todo
//	AddSectorOnEmpty
//	AddSectorOnTiles (Generic)
//		(+rework others to use generic if possible)
