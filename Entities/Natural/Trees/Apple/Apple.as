#include "MakeSeed.as";
#include "AppleCommon.as";

const u16 APPLE_BASE_GROW_TIME = 1200;

void onInit(CBlob@ this)
{
	this.set_string("eat sound", "/AppleBite.ogg");
	this.Tag("ignore_saw");
	this.Tag("ignore sword");
	this.getCurrentScript().tickIfTag = "apple growth";
}

void onTick(CBlob@ this)
{
	CSprite@ s 			= this.getSprite();
	Animation@ anim 	= s.getAnimation("default");

	if (anim is null) return;

	u16 additional_time = this.exists("additional grow time") ? this.get_u16("additional grow time") : 0;

	if (this.getTickSinceCreated() > APPLE_BASE_GROW_TIME + 100 + additional_time && s.getFrame() != 0)  // full apple - stop ticking now
	{
		anim.SetFrameIndex(0);
		this.Untag("apple growth");
		this.AddScript("Eatable.as");
	}
	else if (this.getTickSinceCreated() > APPLE_BASE_GROW_TIME + 50 + additional_time && s.getFrame() != 2)  // medium apple
	{
		anim.SetFrameIndex(2);
	}
	else if (this.getTickSinceCreated() > APPLE_BASE_GROW_TIME + additional_time && s.getFrame() != 1) // small apple
	{
		anim.SetFrameIndex(1);
		//this.setAngleDegrees(0);
	}
	else if (this.getTickSinceCreated() == 0) // flower
	{	
		anim.SetFrameIndex(XORRandom(3) + 3); // 3, 4 or 5
		MakeStatic(this);
		if (!this.exists("additional grow time"))
		{
			this.set_u16("additional grow time", XORRandom(350));
			this.Sync("additional grow time", true);
		}
		//this.setAngleDegrees(XORRandom(360));
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point)
{
	CSprite@ s = this.getSprite();

	if (this.getShape().vellen > 6.5f)
	{
		s.PlayRandomSound("AppleThud.ogg");
	}
	
	/*
	if (blob !is null 
		&& blob.getName() == "arrow"
		&& !this.hasTag("apple growth")) 		// make full apple fall down
	{
		MakeNonStatic(this);
	}
	*/
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return true;
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	MakeNonStatic(this);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	bool still_growing = this.hasTag("apple growth");
	bool still_hanging = this.hasTag("growing on tree");
	bool overlapping = this.isOverlapping(byBlob);

	return !still_growing && 
			(still_hanging && overlapping) || !still_hanging;
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic && this.hasTag("apply velocity"))
	{
		s16 horizontal_vel = (XORRandom(2) == 0) ? -1 : 1;
		this.setVelocity(Vec2f(horizontal_vel,-2 - XORRandom(4)));
		this.Untag("apply velocity");
	}
}
