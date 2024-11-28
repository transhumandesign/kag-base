//fall if not supported by adjacent

#include "StaticToggleCommon.as";

const string time_prop = "_collapse adjacent time";
const string angle_prop = "_collapse angle";
const u32 collapse_time = 10 * getTicksASecond();

void onInit(CBlob@ this)
{
	if (shouldCollapse(this))
	{
		this.Tag("will_soon_collapse");
	}

	this.getCurrentScript().tickFrequency = 30;
}


void onTick(CBlob@ this)
{
	if (!this.getShape().isStatic()) //only do anything if we're staticed
		return;

	if (shouldCollapse(this))
	{
		this.getCurrentScript().tickFrequency = 4;
		this.Tag("will_soon_collapse");

		if (isClient())
		{
			CSprite@ sprite = this.getSprite();

			if (sprite !is null)
			{
				sprite.ResetWorldTransform();
				sprite.RotateAllBy(f32(XORRandom(100) - 50) / 5.0f /* random 10 degree deflection */ , Vec2f());
			}
		}

		if (isServer())
		{
			if (!this.exists(time_prop) || this.get_u32(time_prop) == 0)
				this.set_u32(time_prop, getGameTime());

			f32 time = this.get_u32(time_prop);
			if (getGameTime() - time > collapse_time)
			{
				StaticOff(this);
				this.SendCommand(this.getCommandID("static off"));
				this.getCurrentScript().tickFrequency = 0;
			}
		}
	}
	else
	{
		this.Untag("will_soon_collapse");
		this.getCurrentScript().runFlags |= Script::remove_after_this;

		if (isClient())
		{
			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
			{
				sprite.ResetWorldTransform();
			}
		}
	}
}

bool shouldCollapse(CBlob@ this)
{
	CMap@ map = this.getMap();
	const f32 ts = map.tilesize;

	Vec2f pos = this.getPosition();

	bool surface = map.isTileSolid(pos + Vec2f(-ts, 0)) ||
	               map.isTileSolid(pos + Vec2f(ts, 0)) ||
	               map.isTileSolid(pos + Vec2f(0, -ts)) ||
	               map.isTileSolid(pos + Vec2f(0, ts));

	return getGameTime() > 30 && !surface;
}
