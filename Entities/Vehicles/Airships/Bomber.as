#include "VehicleCommon.as"
#include "Hitters.as"

// Boat logic

void onInit(CBlob@ this)
{
	Vehicle_Setup(this,
	              47.0f, // move speed
	              0.19f,  // turn speed
	              Vec2f(0.0f, -5.0f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;
	Vehicle_SetupAirship(this, v, -350.0f);

	this.SetLight(true);
	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));

	this.set_f32("map dmg modifier", 35.0f);

	//this.getShape().SetOffset(Vec2f(0,0));
	//  this.getShape().getConsts().bullet = true;
//	this.getShape().getConsts().transports = true;

	CSprite@ sprite = this.getSprite();

	// add balloon

	CSpriteLayer@ balloon = sprite.addSpriteLayer("balloon", "Balloon.png", 48, 64);
	if (balloon !is null)
	{
		balloon.addAnimation("default", 0, false);
		int[] frames = { 0, 2, 3 };
		balloon.animation.AddFrames(frames);
		balloon.SetRelativeZ(1.0f);
		balloon.SetOffset(Vec2f(0.0f, -26.0f));
	}

	CSpriteLayer@ background = sprite.addSpriteLayer("background", "Balloon.png", 32, 16);
	if (background !is null)
	{
		background.addAnimation("default", 0, false);
		int[] frames = { 3 };
		background.animation.AddFrames(frames);
		background.SetRelativeZ(-5.0f);
		background.SetOffset(Vec2f(0.0f, -5.0f));
	}

	CSpriteLayer@ burner = sprite.addSpriteLayer("burner", "Balloon.png", 8, 16);
	if (burner !is null)
	{
		{
			Animation@ a = burner.addAnimation("default", 3, true);
			int[] frames = { 41, 42, 43 };
			a.AddFrames(frames);
		}
		{
			Animation@ a = burner.addAnimation("up", 3, true);
			int[] frames = { 38, 39, 40 };
			a.AddFrames(frames);
		}
		{
			Animation@ a = burner.addAnimation("down", 3, true);
			int[] frames = { 44, 45, 44, 46 };
			a.AddFrames(frames);
		}
		burner.SetRelativeZ(1.5f);
		burner.SetOffset(Vec2f(0.0f, -26.0f));
	}
}

void onTick(CBlob@ this)
{
	if (this.hasAttached())
	{
		if (this.getHealth() > 1.0f)
		{
			VehicleInfo@ v;
			if (!this.get("VehicleInfo", @v)) return;

			Vehicle_StandardControls(this, v);

			//TODO: move to atmosphere damage script
			f32 y = this.getPosition().y;
			if (y < 100)
			{
				if (getGameTime() % 15 == 0)
					this.server_Hit(this, this.getPosition(), Vec2f(0, 0), y < 50 ? (y < 0 ? 2.0f : 1.0f) : 0.25f, 0, true);
			}
		}
		else
		{
			this.server_DetachAll();
			this.setAngleDegrees(this.getAngleDegrees() + (this.isFacingLeft() ? 1 : -1));
			if (this.isOnGround() || this.isInWater())
			{
				this.server_SetHealth(-1.0f);
				this.server_Die();
			}
			else
			{
				//TODO: effects
				if (getGameTime() % 30 == 0)
					this.server_Hit(this, this.getPosition(), Vec2f(0, 0), 0.05f, 0, true);
			}
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return Vehicle_doesCollideWithBlob_ground(this, blob);
}

// SPRITE

void onInit(CSprite@ this)
{
	this.SetZ(-50.0f);
	this.getCurrentScript().tickFrequency = 5;
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	f32 ratio = 1.0f - (blob.getHealth() / blob.getInitialHealth());
	this.animation.setFrameFromRatio(ratio);

	CSpriteLayer@ balloon = this.getSpriteLayer("balloon");
	if (balloon !is null)
	{
		if (blob.getHealth() > 1.0f)
			balloon.animation.frame = Maths::Min((ratio) * 3, 1.0f);
		else
			balloon.animation.frame = 2;
	}

	CSpriteLayer@ burner = this.getSpriteLayer("burner");
	AttachmentPoint@ ap = blob.getAttachments().getAttachmentPoint("FLYER");
	if (burner !is null && ap !is null)
	{
		const bool up = ap.isKeyPressed(key_action1);
		const bool down = ap.isKeyPressed(key_action2) || ap.isKeyPressed(key_down);
		burner.SetOffset(Vec2f(0.0f, -14.0f));
		if (up)
		{
			blob.SetLightColor(SColor(255, 255, 240, 200));
			burner.SetAnimation("up");
		}
		else if (down)
		{
			blob.SetLightColor(SColor(255, 255, 200, 171));
			burner.SetAnimation("down");
		}
		else
		{
			blob.SetLightColor(SColor(255, 255, 240, 171));
			burner.SetAnimation("default");
		}
	}
}
