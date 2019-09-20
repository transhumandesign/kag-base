shared class BuildBlock
{
	TileType tile;
	string name;
	CBitStream reqs;
	string icon;
	string description;
	bool buildOnGround;
	Vec2f size; // used by buildOnGround blobs
	bool temporaryBlob;

	BuildBlock() {} // required for handles to work

	BuildBlock(TileType _tile, string _name, string _icon, string _desc)
	{
		tile = _tile;
		name = _name;
		icon = _icon;
		description = _desc;
		temporaryBlob = true;
		buildOnGround = false;
	}
};

u8 getBlockIndexByTile(CBlob@ this, TileType tile)
{
	BuildBlock[][]@ blocks;
	if (this.get("blocks", @blocks))
	{
		const u8 PAGE = this.get_u8("build page");

		for(uint i = 0; i < blocks[PAGE].length; i++)
		{
			BuildBlock@ b = blocks[PAGE][i];
			if (b.tile == tile)
			{
				return i;
			}
		}
	}

	return 255;
}

BuildBlock@ getBlockByIndex(CBlob@ this, u8 index)
{
	BuildBlock[][]@ blocks;
	if (this.get("blocks", @blocks))
	{
		u8 page = this.get_u8("build page");
		if (index >= blocks[page].length) {
			return null;
		} else {
			return @blocks[page][index];
		}
	}

	return null;
}

/*
// not used
TileType getTileByBlockIndex(CBlob@ this, u8 index)
{
	BuildBlock[][]@ blocks;
	if (this.get("blocks", @blocks))
	{
		if (index >= 0 && index < blocks.length)
		{
			return blocks[index].tile;
		}
	}

	warn("getTileByBlockIndex() blocks not found");
	return 0;
}
*/
