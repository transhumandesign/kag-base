// Nursery

#include "ProductionCommon.as";
#include "Requirements.as"
#include "MakeSeed.as"
#include "WARCosts.as";

void onInit( CBlob@ this )
{
	this.set_string("produce sound", "/PopIn");

	{
		addSeedItem( this, "tree_pine", "Pine tree seed", 8, 3 );
	}
	{
		addSeedItem( this, "tree_bushy", "Oak tree seed", 8, 3 );
	}
	{
		addSeedItem( this, "grain_plant", "Grain plant seed", 8, 3 );
	}
	{
		addSeedItem( this, "bush", "Bush seed", 8, 3 );
	}
	{
		addSeedItem( this, "flowers", "Flowers seed", 8, 3 );
	}

	this.set_TileType("background tile", CMap::tile_wood_back);
	this.getSprite().getConsts().accurateLighting = true;

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;
	
	this.Tag("inventory access");
	this.set_string("autograb blob", "seed");
	this.inventoryButtonPos = Vec2f(0.0f, -24.0f);
}

// leave a pile of wood	after death
void onDie(CBlob@ this)
{
	if (getNet().isServer())
	{
		CBlob@ blob = server_CreateBlob( "mat_wood", this.getTeamNum(), this.getPosition() );
		if (blob !is null)
		{
			blob.server_SetQuantity( COST_WOOD_NURSERY/2 );
		}
	}
}
