// Dorm

#include "WARCosts.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "MigrantCommon.as";

namespace MigrantState
{
enum State {
	none,
	absent,
	sleeping
};
};

const int migrant_tickets = 1;
const int migrant_replenish_ticks = 300;

void onInit( CBlob@ this )
{	 
	this.set_TileType("background tile", CMap::tile_wood_back);

	// from TheresAMigrantInTheRoom
	this.set_bool("migrants auto", true);
	this.set_u8("migrants max", 1 );		   		 // how many physical migrants it needs
	this.set_u32("next respawn time", 0 ); 		
	this.addCommandID("respawn");		   
	this.getCurrentScript().tickFrequency = 49;

	this.Tag("bed"); // allow spawning in WAR

	// SHOP

	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(2,2));	
	this.set_string("shop description", "Upgrade");
	this.set_u8("shop icon", 12);
	this.set_bool("shop available", false );

	//{
	//	ShopItem@ s = addShopItem( this, "Barracks", "$barracks$", "barracks", descriptions[41] );
	//	AddRequirement( s.requirements, "blob", "mat_stone", "Stone", COST_STONE_BARRACKS );
	//	AddRequirement( s.requirements, "tech", "barracks", "Barracks Technology" );
	//}	

	//{
	//	ShopItem@ s = addShopItem( this, "Research", "$research$", "research", descriptions[49] );
	//	AddRequirement( s.requirements, "blob", "mat_stone", "Stone", COST_STONE_RESEARCH );
	//}

}	  

void onChangeMigrantState(CBlob@ this, MigrantState::State s)
{
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ bed = sprite.getSpriteLayer( "bed" );
	if (bed is null) return;
	CSpriteLayer@ zzz = sprite.getSpriteLayer( "zzz" );
	if (zzz is null) return;
	CSpriteLayer@ fire = sprite.getSpriteLayer( "fire" );
	if (fire is null) return;
//	if (s == this.get_u8("migrant state"))
//		return;

	this.set_u8("migrant state", s );
	
	if (s == MigrantState::none)
	{
		zzz.SetVisible(false);
		fire.SetVisible(false);
		bed.SetFrameIndex(0);
		sprite.SetFrameIndex(0);
		this.SetLight(false);
	}
	else if (s == MigrantState::absent)
	{
		fire.SetVisible(true);
		DecMigrantCount( this );

		if (this.get_u8("migrants count") == 0)	  // no migrant remove zzz layer
		{
			zzz.SetVisible( false );
			bed.SetFrameIndex(1);
			sprite.SetFrameIndex(1);	 
		}
	}
	else if (s == MigrantState::sleeping)
	{
		fire.SetVisible(true);
		if (!zzz.isVisible()) {			
			this.getSprite().PlaySound("/MigrantSleep");
		}
		zzz.SetVisible( true );
		bed.SetFrameIndex(2);
		sprite.SetFrameIndex(1);
		this.SetLight(true);
	
		if (needsReplenishMigrant(this)) {
			AddMigrantCount( this );
		}
	}
	
	this.SetLightRadius(32.0f );
}

void onTick( CBlob@ this )
{
 
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	// get no migrant button
	if (!this.get_bool("shop available"))
	{
		CBlob@ carried = caller.getCarriedBlob();
		if (carried is null || !carried.hasTag("migrant"))
		{
			CButton@ button = caller.CreateGenericButton( "$builder$", Vec2f(0, 0), this, 0, "Requires migrant" );
			if (button !is null) {
				button.SetEnabled( false );
			}
		}
	}
}

// leave a pile of wood	after death
void onDie(CBlob@ this)
{
	if (getNet().isServer())
	{
		CBlob@ blob = server_CreateBlob( "mat_wood", this.getTeamNum(), this.getPosition() );
		if (blob !is null)
		{
			blob.server_SetQuantity( COST_WOOD_DORM/2 );
		}
	}
}


void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	CSprite@ sprite = this.getSprite();
	if (cmd == this.getCommandID("put migrant") && !isRoomFullOfMigrants(this))
	{	
		onChangeMigrantState(this, MigrantState::sleeping);
		this.set_bool("shop available", true );
	}
	else if (cmd == this.getCommandID("out migrant"))
	{	
		if (this.get_u8("migrants count") <= 1)
		{
			onChangeMigrantState(this, MigrantState::none );
			this.set_bool("shop available", false );
		}
	}
	else if (cmd == this.getCommandID("respawn"))
	{	
		onChangeMigrantState(this, MigrantState::absent );
		const u32 spawnTime = getGameTime() + migrant_replenish_ticks;   
		this.set_u32("next respawn time", spawnTime );
	}
	else if (cmd == this.getCommandID("shop buy"))
	{
		this.getSprite().PlaySound("/Construct.ogg" ); 
		this.getSprite().getVars().gibbed = true;
		this.server_Die();
	}
	else if (cmd == this.getCommandID("shop made item"))   // will this get recieved, caise of Die() ?
	{
		u16 callerID;
		if (!params.saferead_u16(callerID))
			return;		
		u16 blobID;
		if (!params.saferead_u16(blobID))
			return;		
		CBlob@ blob = getBlobByNetworkID(blobID);
		if (blob !is null)
		{	
			blob.set_u8("migrants count", this.get_u8("migrants count") );
			this.set_u8("migrants count", 0);
		}
	}
}


// SPRITE

void onInit(CSprite@ this)
{
	this.SetFrame(0);

	CSpriteLayer@ bed = this.addSpriteLayer( "bed", 24,16 );
	if(bed !is null)
	{
		bed.addAnimation("default",0,false);
		int[] frames = {6,7,17};
		bed.animation.AddFrames(frames);
		bed.SetOffset(Vec2f(5, 5));
	}

	CSpriteLayer@ zzz = this.addSpriteLayer( "zzz", 8,8 );
	if (zzz !is null)
	{
		zzz.addAnimation("default",10,true);
		int[] frames = {83,114,83,115};
		zzz.animation.AddFrames(frames);
		zzz.SetOffset(Vec2f(0 ,-7));
		zzz.SetHUD(true);
	}
	
	CSpriteLayer@ fire = this.addSpriteLayer( "fire", 8,8 );
	if(fire !is null)
	{
		fire.addAnimation("default",3,true);
		int[] frames = {10,11,42,43};
		fire.animation.AddFrames(frames);
		fire.SetOffset(Vec2f(-9, 5));
		fire.SetRelativeZ(0.1f);
	}
	
	onChangeMigrantState(this.getBlob(), MigrantState::none);
}
