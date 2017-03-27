// Storage

#include "WARCosts.as";

void onInit( CBlob@ this )
{
	this.set_TileType("background tile", CMap::tile_wood_back);
	this.Tag("storage");
}

// leave a pile of stone after death
void onDie(CBlob@ this)
{
	if (getNet().isServer())
	{
		CBlob@ blob = server_CreateBlob( "mat_wood", this.getTeamNum(), this.getPosition() );
		if (blob !is null)
		{
			blob.server_SetQuantity( COST_WOOD_STORAGE/2 );
		}
	}
}

// we use a custom inv
bool isInventoryAccessible( CBlob@ this, CBlob@ forBlob )
{
	return false;
}
