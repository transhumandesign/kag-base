#include "VehicleCommon.as"

// Boat logic

//attachment point of the sail
const int sail_index = 0;

void onInit(CBlob@ this)
{
	Vehicle_Setup(this,
	              300.0f, // move speed
	              0.18f,  // turn speed
	              Vec2f(0.0f, -2.5f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	Vehicle_SetupWaterSound(this, v, "BoatRowing",  // movement sound
	                        0.0f, // movement sound volume modifier   0.0f = no manipulation
	                        0.0f // movement sound pitch modifier     0.0f = no manipulation
	                       );
	this.getShape().SetOffset(Vec2f(0, 12));
	this.getShape().SetCenterOfMassOffset(Vec2f(-1.5f, 6.0f));
	this.getShape().getConsts().transports = true;
	this.getShape().getConsts().bullet = false;
	this.set_f32("map dmg modifier", 150.0f);

	// add custom capture zone
	getMap().server_AddMovingSector(Vec2f(-27.0f, -16.0f), Vec2f(28.0f, 4.0f), "capture zone "+this.getNetworkID(), this.getNetworkID());

	//block knight sword
	this.Tag("blocks sword");

	// additional shape

	Vec2f[] frontShape;
	frontShape.push_back(Vec2f(74.0f, -19.0f));
	frontShape.push_back(Vec2f(78.0f, -19.0f));
	frontShape.push_back(Vec2f(80.0f, 0.0f));
	frontShape.push_back(Vec2f(76.0f, 0.0f));
	this.getShape().AddShape(frontShape);

	Vec2f[] backShape;
	backShape.push_back(Vec2f(8.0f, -8.0f));
	backShape.push_back(Vec2f(10.0f, 0.0f));
	backShape.push_back(Vec2f(6.0f, 0.0f));
	this.getShape().AddShape(backShape);

	// sprites

	CSprite@ sprite = this.getSprite();
	const Vec2f mastOffset(-1, -3);

	// add mast
	CSpriteLayer@ mast = sprite.addSpriteLayer("mast", 48, 64);
	if (mast !is null)
	{
		Animation@ anim = mast.addAnimation("default", 0, false);
		int[] frames = {4, 5};
		anim.AddFrames(frames);
		mast.SetOffset(Vec2f(9, -6) + mastOffset);
		mast.SetRelativeZ(-10.0f);
	}

	if (!this.hasTag("no sail")) //joining clients
	{
		// add sail
		CSpriteLayer@ sail = sprite.addSpriteLayer("sail " + sail_index, 32, 32);
		if (sail !is null)
		{
			Animation@ anim = sail.addAnimation("default", 3, false);
			int[] frames = {3, 7, 11};
			anim.AddFrames(frames);
			sail.SetOffset(Vec2f(1, -10) + mastOffset);
			sail.SetRelativeZ(-9.0f);
			sail.SetVisible(false);
		}
	}
	else
	{
		if (mast !is null)
		{
			mast.animation.frame = 1;
		}
	}

	// add head
	CSpriteLayer@ head = sprite.addSpriteLayer("head", 16, 16);
	if (head !is null)
	{
		Animation@ anim = head.addAnimation("default", 0, false);
		anim.AddFrame(5);
		head.SetOffset(Vec2f(-35, -13));
		head.SetRelativeZ(1.0f);
	}

	sprite.animation.setFrameFromRatio(1.0f - (this.getHealth() / this.getInitialHealth()));

	//add minimap icon
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 6, Vec2f(16, 8));
}

void onTick(CBlob@ this)
{
	if (this.hasAttached())
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

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	const f32 tier1 = this.getInitialHealth() * 0.6f;
	const f32 health = this.getHealth();

	if (health < tier1 && !this.hasTag("no sail"))
	{
		this.Tag("no sail");

		CSprite@ sprite = this.getSprite();

		CSpriteLayer@ mast = sprite.getSpriteLayer("mast");
		if (mast !is null)
			mast.animation.frame = 1;

		CSpriteLayer@ sail = sprite.getSpriteLayer("sail " + sail_index);
		if (sail !is null)
			sail.SetVisible(false);
	}
}
