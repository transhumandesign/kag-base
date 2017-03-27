
#include "Hitters.as";
#include "SplashWater.as";

//config

const int splash_width = 9;
const int splash_height = 7;
const int splashes = 3;

//logic
void onInit(CBlob@ this)
{
	//todo: some tag-based keys to take interference (doesn't work on net atm)
	/*AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1 | key_action2 | key_action3);
	}*/

	this.getSprite().ReloadSprites(0, 0);
	this.addCommandID("splash");
	this.set_u8("filled", 0);

	this.getCurrentScript().runFlags |= Script::tick_attached;
}

void onTick(CBlob@ this)
{
	u8 filled = this.get_u8("filled");
	if (filled < splashes && this.isInWater())
	{
		this.set_u8("filled", splashes);
		this.set_u8("water_delay", 30);
		this.getSprite().SetAnimation("full");
	}

	if (filled != 0)
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		u8 water_delay = this.get_u8("water_delay");

		if (water_delay > 0)
		{
			this.set_u8("water_delay", water_delay - 1);
		}
		else if (point.getOccupied() !is null && point.getOccupied().isMyPlayer() && point.getOccupied().isKeyJustPressed(key_action1) && !this.isInWater())
		{
			this.SendCommand(this.getCommandID("splash"));
			this.set_u8("water_delay", 30);
		}
	}
}

void onDie(CBlob@ this)
{
	if (this.get_u8("filled") > 0)
	{
		Splash(this);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("splash"))
	{
		Splash(this);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point)
{
	if (solid && getNet().isServer() && this.getShape().vellen > 6.8f && this.get_u8("filled") > 0)
	{
		this.SendCommand(this.getCommandID("splash"));
	}

}

const uint splash_halfwidth = splash_width / 2;
const uint splash_halfheight = splash_height / 2;
const f32 splash_offset = 0.7f;

void Splash(CBlob@ this)
{
	//extinguish fire

	u8 filled = this.get_u8("filled");
	if (filled > 0)
		filled--;

	if (filled == 0)
	{
		filled = 0;
		this.getSprite().SetAnimation("empty");
	}
	this.set_u8("filled", filled);

	Splash(this, splash_halfwidth, splash_halfheight, splash_offset, false);
}


//sprite

void onInit(CSprite@ this)
{
	this.SetAnimation("empty");
	if (this.getBlob().get_u8("filled") > 0)
	{
		this.SetAnimation("full");
	}
}
