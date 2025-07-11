// Bush logic

#include "canGrow.as";

void onInit(CBlob@ this)
{
	this.set_bool("grown", true);
	this.Tag("builder always hit");
	this.Tag("scenary");
	this.getCurrentScript().tickIfTag = "is animated";
}

//void onDie( CBlob@ this )
//{
//	//TODO: make random item
//}


void onTick(CBlob@ this)
{
	if (!isClient()) return;

	CSprite@ s = this.getSprite();

	if (s !is null &&
		this.get_u32("anim end time") <= getGameTime())
	{
		Animation@ anim = s.getAnimation("wiggle");
		if (anim is null)	return;
		s.SetAnimation(anim);
		anim.loop = false;
		//could set a random frame here, but it wouldn't be synced
		this.Untag("is animated");
	}
}

//sprite

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (v_fastrender)	return;

	CSprite@ s = this.getSprite();

	if (s !is null &&
		blob !is null &&
		blob.hasTag("player") &&
		!this.hasTag("is animated"))
	{	
		Animation@ anim = s.getAnimation("wiggle");
		if (anim is null)	return;
		anim.loop = true;
		anim.time = 5;
		this.Tag("is animated");
		this.set_u32("anim end time", getGameTime() + 8);
		s.PlayRandomSound("LeafRustle");
	}
}

void onInit(CSprite@ this)
{	
	LoadSprite(this);
}

void LoadSprite(CSprite@ this)
{
	CBlob@ b = this.getBlob();
	u16 netID = b.getNetworkID();
	this.SetFacingLeft(((netID % 13) % 2) == 0);
	this.SetZ(10.0f);

	Animation@ anim_wiggle = this.addAnimation("wiggle", 0, false);

	int offset = (netID % 5) * 3;

	if (anim_wiggle !is null)
	{
		anim_wiggle.AddFrame(offset);
		anim_wiggle.AddFrame(offset + 1);
		anim_wiggle.AddFrame(offset + 2);
		anim_wiggle.frame = 2;
		this.SetAnimation(anim_wiggle);
	}

	this.ReloadSprite("Bushes.png");
}
