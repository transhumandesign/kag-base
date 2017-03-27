// Bed

#include "Help.as"

void onInit( CBlob@ this )
{		 	
	this.getShape().getConsts().mapCollisions = false;	
	//randomize facing
	this.SetFacingLeft( XORRandom(2) == 0 );

	 // from TheresAMigrantInTheRoom
	this.set_bool("migrants auto", true);
	this.set_u8("migrants max", 1);

	this.getCurrentScript().tickFrequency = 179;
	
	this.Tag("dead head");
}

void onTick( CBlob@ this )
{
	if (XORRandom(14) == 0 && this.get_u8("migrants count") > 0) {
		this.getSprite().PlaySound("/MigrantSleep");
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	CSprite@ sprite = this.getSprite();
	if (cmd == this.getCommandID("put migrant"))
	{	
		sprite.SetFrame(1);
		sprite.getSpriteLayer( "zzz" ).SetVisible( true );
		//this.Tag("had migrant");
	}
	else if (cmd == this.getCommandID("out migrant"))
	{	
		sprite.SetFrame(0);
		sprite.getSpriteLayer( "zzz" ).SetVisible( false );
	}
}

																																													
// SPRITE

void onInit(CSprite@ this)
{
	this.SetZ(-50); //background
	this.SetFrame(0);

	CSpriteLayer@ zzz = this.addSpriteLayer( "zzz", 8,8 );		 
	if (zzz !is null)
	{
		zzz.addAnimation("default",3,true);
		int[] frames = {7,14,15};
		zzz.animation.AddFrames(frames);
		zzz.SetOffset(Vec2f(-7 * (this.getBlob().isFacingLeft() ? -1.0f : 1.0f),-7));
		zzz.SetVisible( false );
		zzz.SetLighting( false );
		zzz.SetHUD( true );
	}
}
