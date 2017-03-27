// Barracks

#include "ProductionCommon.as";
#include "WARCosts.as";

#include "ClassSelectMenu.as";
#include "StandardRespawnCommand.as";

void onInit( CBlob@ this )
{
	InitClasses( this );
	InitRespawnCommand( this );
	this.set_TileType("background tile", CMap::tile_castle_back);					
	this.Tag("change class store inventory");		
}

 
// leave a pile of stone	after death
void onDie(CBlob@ this)
{
	if (getNet().isServer())
	{
		CBlob@ blob = server_CreateBlob( "mat_stone", this.getTeamNum(), this.getPosition() );
		if (blob !is null)
		{
			blob.server_SetQuantity( COST_STONE_BARRACKS/2 );
		}
	}
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	CBitStream params;
	params.write_u16( caller.getNetworkID() );
	if (canChangeClass( this, caller ))	 
	{			
		if ((this.getPosition() - caller.getPosition()).Length() < 18.0f) {
			BuildRespawnMenuFor( this, caller );
		}
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	{
		onRespawnCommand( this, cmd, params );
	}
}

//sprite - bed?
void onInit(CSprite@ this)
{
	this.SetZ(-50); //background
	
	CBlob@ blob = this.getBlob();
	/*CSpriteLayer@ front = this.addSpriteLayer( "front layer", this.getFilename() , this.getFrameWidth(), this.getFrameHeight(), blob.getTeamNum(), blob.getSkinNum() );

    if (front !is null)
    {
        Animation@ anim = front.addAnimation( "default", 0, false );
        anim.AddFrame(0);
        anim.AddFrame(1);
        anim.AddFrame(2);
        front.SetRelativeZ( 1000 );
    }*/
}
