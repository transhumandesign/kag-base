
//use for setting the underlying tilemap flags conveniently from script
// TODO: other flags, as needed

void SetSolidFlag(CBlob@ this, bool solid)
{
	CMap@ map = getMap();
	u32 offset = map.getTileOffset(this.getPosition());
	if (solid)
		map.AddTileFlag(offset, Tile::SOLID);
	else
		map.RemoveTileFlag(offset, Tile::SOLID);
}

void SetFlammableFlag(CBlob@ this, bool flammable)
{
	CMap@ map = getMap();
	u32 offset = map.getTileOffset(this.getPosition());
	if (flammable)
		map.AddTileFlag(offset, Tile::FLAMMABLE);
	else
		map.RemoveTileFlag(offset, Tile::FLAMMABLE);
}
