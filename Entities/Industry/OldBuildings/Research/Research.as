// Research

#include "WARCosts.as"
#include "ResearchCommon.as"

void onInit( CBlob@ this )
{
	this.set_TileType("background tile", CMap::tile_castle_back);					
}

// leave a pile of stone	after death
void onDie(CBlob@ this)
{
	if (getNet().isServer())
	{
		CBlob@ blob = server_CreateBlob( "mat_stone", this.getTeamNum(), this.getPosition() );
		if (blob !is null)
		{
			blob.server_SetQuantity( COST_STONE_RESEARCH/2 );
		}

		// drop scroll with techs

		ResearchStatus@ stat;
		this.get( "techs", @stat );
		if (stat !is null)
		{
			CBlob@ blob = server_CreateBlobNoInit( "scroll" ); 
			if (blob !is null)
			{
				blob.setPosition( this.getPosition() );
				blob.set_string( "scroll name", this.getTeamNum() == 0 ? "Blue Team's Technology Tome" : "Red Team's Technology Tome" );
				blob.set_u8("scroll icon", 23 );
				blob.set_u8("team colour", this.getTeamNum()); //special - force team colour

				ScrollSet@ scrolls = stat.scrolls;	
				uint count = 0;
				for (uint i = 0; i < scrolls.names.length; i++)
				{	  
					const string defname = scrolls.names[i];
					ScrollDef@ def;
					scrolls.scrolls.get( defname, @def);
					if (def !is null && def.hasTech())
					{
						blob.set_string( "scroll defname"+count, defname );
						count++;
					}
				}

				blob.Tag("tech"); 
				blob.Init();   
			}
		}
	}
}

bool isInventoryAccessible( CBlob@ this, CBlob@ forBlob )
{
	return false;
}

//sprite - foreground layer :)

void onInit(CSprite@ this)
{
	this.SetZ(-50); //background
	
	CBlob@ blob = this.getBlob();
	CSpriteLayer@ lantern = this.addSpriteLayer( "lantern", "Lantern.png" , 8, 8, blob.getTeamNum(), blob.getSkinNum() );
	
	if (lantern !is null)
    {
		lantern.SetOffset(Vec2f(9,-5));
		
        Animation@ anim = lantern.addAnimation( "default", 3, true );
        anim.AddFrame(0);
        anim.AddFrame(1);
        anim.AddFrame(2);
        
        blob.SetLight(true);
		blob.SetLightRadius( 32.0f );
    }
	
	/*
	CSpriteLayer@ front = this.addSpriteLayer( "front layer", this.getFilename() , this.getFrameWidth(), this.getFrameHeight(), blob.getTeamNum(), blob.getSkinNum() );

    if (front !is null)
    {
        Animation@ anim = front.addAnimation( "default", 0, false );
        anim.AddFrame(0);
        anim.AddFrame(1);
        anim.AddFrame(2);
        front.SetRelativeZ( 1000 );
    }*/
}
