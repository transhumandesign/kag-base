// Grain logic

#include "PlantGrowthCommon.as";

void onInit(CBlob@ this)
{
	this.SetFacingLeft(XORRandom(2) == 0);

	this.getCurrentScript().tickFrequency = 45;
	this.getSprite().SetZ(10.0f);

	this.Tag("builder always hit");

	// this script gets removed so onTick won't be run on client on server join, just onInit
	if (this.hasTag("instant_grow") || this.hasTag("has grain"))
	{
		GrowGrain(this);
	}

	this.Tag("scenary");
}


void onTick(CBlob@ this)
{
	if (this.hasTag(grown_tag))
	{
		GrowGrain(this);
	}
}

void GrowGrain(CBlob @this)
{
	for (int i = 0; i < 3; i++)
	{
		Vec2f offset;
		int v = this.isFacingLeft() ? 0 : 1;
		switch (i)
		{
			case 0: offset = Vec2f(-1 + v, -16); break;
			case 1: offset = Vec2f(2 + v, -10); break;
			case 2: offset = Vec2f(-4 + v, -5); break;
		}

		CSpriteLayer@ grain = this.getSprite().addSpriteLayer("grain", "Entities/Natural/Farming/Grain.png" , 8, 8);

		if (grain !is null)
		{
			Animation@ anim = grain.addAnimation("default", 0, false);
			anim.AddFrame(0);
			grain.SetAnimation("default");
			grain.SetOffset(offset);
			grain.SetRelativeZ(0.01f * (XORRandom(3) == 0 ? -1 : 1));
		}
	}

	this.Tag("has grain");
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
