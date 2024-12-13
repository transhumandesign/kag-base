
#include "Hitters.as";
#include "SplashWater.as";
#include "ArcherCommon.as";
//config

const int splash_width = 9;
const int splash_height = 7;
const int splashes = 2;

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
	this.addCommandID("splash client");

	this.set_u8("filled", this.hasTag("_start_filled") ? splashes : 0);
	this.Tag("ignore fall");
	this.getCurrentScript().runFlags |= Script::tick_attached;
}

void onTick(CBlob@ this)
{
	//(prevent splash when bought filled)
	if (this.getTickSinceCreated() < 10) 
	{
		return;
	}

	if (isServer())
	{
		if (this.isInWater() && this.get_u8("filled") < splashes)
		{
			this.set_u8("filled", splashes);
			this.set_u8("water_delay", 30);
			this.Sync("filled", true);
		}

		if (this.get_u8("filled") != 0)
		{
			AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
			u8 water_delay = this.get_u8("water_delay");

			if (water_delay > 0)
			{
				this.set_u8("water_delay", water_delay - 1);
			}
			else
			{
				CBlob@ occupiedBlob = point.getOccupied();
				if (occupiedBlob !is null && 
					occupiedBlob.isKeyJustPressed(key_action1) && 
					!this.isInWater() &&
					!occupiedBlob.isKeyPressed(key_inventory)) // prevent splash when doing stuff with inventory
				{
					DoSplash(this);
					this.SendCommand(this.getCommandID("splash client"));
					this.set_u8("water_delay", 30);
				}
			}
		}
	}

	if (isClient())
	{
		SetFrame(this, this.get_u8("filled") > 0);
	}
}

void onDie(CBlob@ this)
{
	if (this.get_u8("filled") > 0 || this.hasTag("splash on destroy"))
	{
		DoSplash(this);
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.0f && hitterBlob !is null)
	{
		//spam hit
		if (hitterBlob is this)
		{
			int id = this.getNetworkID();
			this.setVelocity(this.getVelocity() + Vec2f(1,0).RotateBy((id * 933) % 360));
			DepleteWaterCount(this);
			
			if (isClient())
			{
				SetFrame(this, this.get_u8("filled") > 0);
			}
		}
	}

	if (isServer()) 
	{
		const string name = hitterBlob.getName();

		if ((customData == Hitters::water || customData == Hitters::water_stun) &&
		    (name == "waterbomb" || (name == "arrow" && hitterBlob.get_u8("arrow type") == ArrowType::water)) && 
		    !hitterBlob.hasTag("tmp has filled"))
		{
			u8 filled = this.get_u8("filled");
			u8 tmp_filling_left = hitterBlob.get_u8("tmp filling left");
			if (tmp_filling_left == 0) tmp_filling_left = splashes; // up to one full bucket
			
			if (filled < splashes)
			{
				u8 d = Maths::Min(tmp_filling_left, splashes - filled);
				tmp_filling_left -= d;
				hitterBlob.set_u8("tmp filling left" , tmp_filling_left);

				if (tmp_filling_left <= 0)
					hitterBlob.Tag("tmp has filled");

				this.set_u8("water_delay", 5); // only slight delay
				this.set_u8("filled", (filled + d));
				this.Sync("filled", true);
			}
		}
	}

	return damage;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("splash client") && isClient() && !isServer())
	{
		DoSplash(this);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point)
{
	if (solid && isServer() && this.getShape().vellen > 6.8f && this.get_u8("filled") > 0)
	{
		DoSplash(this);
		
		if (!(isClient() && isServer()))
			this.SendCommand(this.getCommandID("splash client"));
	}
}

void DepleteWaterCount(CBlob@ this)
{
	if (!isServer()) { return; }

	u8 filled = this.get_u8("filled");	
	if (filled > 0)
	{
		if (this.getHealth() <= 0)
		{
			this.Tag("splash on destroy");
			this.Sync("splash on destroy", true);
		}
		
		filled--;
	}

	this.set_u8("filled", filled);
	this.Sync("filled", true);
}

const uint splash_halfwidth = splash_width / 2;
const uint splash_halfheight = splash_height / 2;
const f32 splash_offset = 0.7f;

void DoSplash(CBlob@ this)
{
	//extinguish fire

	DepleteWaterCount(this);
	Splash(this, splash_halfwidth, splash_halfheight, splash_offset, false);
	
	if (isClient())
	{
		SetFrame(this, this.get_u8("filled") > 0);
	}
}

//sprite

void onInit(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	bool filled = blob.get_u8("filled") > 0;
	SetFrame(blob, filled);
}

void SetFrame(CBlob@ blob, bool filled)
{
	Animation@ animation = blob.getSprite().getAnimation("default");
	if (animation !is null)
	{
		u8 index = filled ? 1 : 0;
		animation.SetFrameIndex(index);
		blob.inventoryIconFrame = index;
	}
}
