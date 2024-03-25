
bool isVoidedOut(CBlob@ this)
{
	CMap@ map = getMap();
	if (this.getPosition().y > map.tilemapheight * map.tilesize)
	{	
		return true;
	}
	return false;
}