#include "VehicleCommon.as"
#include "ClassSelectMenu.as";
#include "StandardRespawnCommand.as";
#include "GenericButtonCommon.as";
#include "Costs.as";
//#include "Requirements_Tech.as";

// Boat logic

void onInit(CBlob@ this)
{
	Vehicle_Setup(this,
	              320.0f, // move speed
	              0.47f,  // turn speed
	              Vec2f(0.0f, -5.0f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	Vehicle_SetupWaterSound(this, v, "BoatRowing",  // movement sound
	                        0.0f, // movement sound volume modifier   0.0f = no manipulation
	                        0.0f // movement sound pitch modifier     0.0f = no manipulation
	                       );

	Vec2f pos_off(0, 0);
	this.set_f32("map dmg modifier", 50.0f);

	//block knight sword
	this.Tag("blocks sword");

	//bomb arrow damage value
	this.set_f32("bomb resistance", 3.1f);

	this.getShape().SetOffset(Vec2f(0, 16));
	this.getShape().getConsts().bullet = false;
	this.getShape().getConsts().transports = true;

	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			ap.offsetZ = 10.0f;
		}
	}

	this.Tag("respawn");

	InitClasses(this);
	this.Tag("change class store inventory");

	InitCosts();
	this.set_s32("gold building amount", CTFCosts::warboat_gold);

	// additional shapes

	//top bit
	//{
	//	Vec2f[] shape = { Vec2f( 39.0f,  4.0f ) -pos_off,
	//					  Vec2f( 67.0f,  4.0f ) -pos_off,
	//					  Vec2f( 73.0f,  7.0f ) -pos_off,
	//					  Vec2f( 48.0f,  7.0f ) -pos_off };
	//	this.getShape().AddShape( shape );
	//}

	//front bits
	{
		Vec2f[] shape = { Vec2f(43.0f,  4.0f) - pos_off,
		                  Vec2f(73.0f,  7.0f) - pos_off,
		                  Vec2f(93.0f,  36.0f) - pos_off,
		                  Vec2f(69.0f,  24.0f) - pos_off
		                };
		this.getShape().AddShape(shape);
	}

	//{
	//	Vec2f[] shape = { Vec2f( 69.0f,  23.0f ) -pos_off,
	//					  Vec2f( 93.0f,  31.0f ) -pos_off,
	//					  Vec2f( 79.0f,  43.0f ) -pos_off,
	//					  Vec2f( 69.0f,  45.0f ) -pos_off };
	//	this.getShape().AddShape( shape );
	//}

	//back bit
	{
		Vec2f[] shape = { Vec2f(8.0f,  25.5f) - pos_off,
		                  Vec2f(14.0f, 25.5f) - pos_off,
		                  Vec2f(14.0f, 36.0f) - pos_off,
		                  Vec2f(11.0f, 36.0f) - pos_off
		                };
		this.getShape().AddShape(shape);
	}
	//rudder
	//{
	//	Vec2f[] shape = { Vec2f( 8.0f,  48.0f ) -pos_off,
	//					  Vec2f( 24.0f, 48.0f ) -pos_off,
	//					  Vec2f( 16.0f, 52.0f ) -pos_off,
	//					  Vec2f( 12.0f, 52.0f ) -pos_off };
	//	this.getShape().AddShape( shape );
	//}

	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ front = sprite.addSpriteLayer("front layer", sprite.getConsts().filename, 96, 56);
	if (front !is null)
	{
		front.addAnimation("default", 0, false);
		int[] frames = { 0, 4, 5 };
		front.animation.AddFrames(frames);
		front.SetRelativeZ(55.0f);
		front.SetOffset(Vec2f(-6, 0));
	}

	CSpriteLayer@ flag = sprite.addSpriteLayer("flag", sprite.getConsts().filename, 40, 56);
	if (flag !is null)
	{
		flag.addAnimation("default", XORRandom(3) + 3, true);
		int[] frames = { 5, 4, 3 };
		flag.animation.AddFrames(frames);
		flag.SetRelativeZ(-5.0f);
		flag.SetOffset(Vec2f(22, -24));
	}

	this.set_f32("oar offset", 54.0f);

	CMap@ map = getMap();
	// add pole ladder
	map.server_AddMovingSector(Vec2f(-26.0f, -32.0f), Vec2f(-10.0f, 0.0f), "ladder", this.getNetworkID());
	// add back ladder
	map.server_AddMovingSector(Vec2f(-48.0f, 0.0f), Vec2f(-33.0f, 20.0f), "ladder", this.getNetworkID());
	// add custom capture zone
	map.server_AddMovingSector(Vec2f(-34.0f, -30.0f), Vec2f(16.0f, 5.0f), "capture zone "+this.getNetworkID(), this.getNetworkID());

	//set custom minimap icon
	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 7, Vec2f(16, 8));
	this.SetMinimapRenderAlways(true);

	// mounted bow
	if (isServer())// && hasTech( this, "mounted bow"))
	{
		CBlob@ bow = server_CreateBlob("mounted_bow", this.getTeamNum(), this.getPosition());
		if (bow !is null)
		{
			this.server_AttachTo(bow, "BOW");
			this.set_u16("bowid", bow.getNetworkID());
		}
	}
}

void onTick(CBlob@ this)
{
	if (this.hasAttached()) //driver, seat or gunner, or just created
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v)) return;

		Vehicle_StandardControls(this, v);
	}

	if (this.getTickSinceCreated() % 12 == 0)
	{
		Vehicle_DontRotateInWater(this);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	//if (blob.getShape().getConsts().platform)
		//return false;
	return Vehicle_doesCollideWithBlob_boat(this, blob);
}

void onTick(CSprite@ this)
{
	this.SetZ(-50.0f);
	CBlob@ blob = this.getBlob();
	this.animation.setFrameFromRatio(1.0f - (blob.getHealth() / blob.getInitialHealth()));
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (caller.getTeamNum() == this.getTeamNum())
	{
		caller.CreateGenericButton("$change_class$", Vec2f(13, 4), this, buildSpawnMenu, getTranslatedString("Change class"));
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onRespawnCommand(this, cmd, params);
}

void onDie(CBlob@ this)
{
	if (this.exists("bowid"))
	{
		CBlob@ bow = getBlobByNetworkID(this.get_u16("bowid"));
		if (bow !is null)
		{
			bow.server_Die();
		}
	}
}
