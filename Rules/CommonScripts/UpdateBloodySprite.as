
#include "SpikeCommon.as";

// used in ToggleBloodyStuff.as and SplashWater.as

void UpdateBloodySprite(CBlob@ this)
{
	if (!isClient())	return;
	
	string name = this.getName();
	CSprite@ sprite = this.getSprite();
	
	if (name == "saw")
	{
		CSpriteLayer@ chop = sprite.getSpriteLayer("chop");

		if (chop !is null)
		{	
			chop.animation.frame = this.hasTag("bloody") && !g_kidssafe ? 1 : 0;
		}
	}
	else if (name == "spikes")
	{
		f32 hp = this.getHealth();
		f32 full_hp = this.getInitialHealth();
		int frame = (hp > full_hp * 0.9f) ? 0 : ((hp > full_hp * 0.4f) ? 1 : 2);

		if (this.hasTag("bloody") && !g_kidssafe)
		{
			frame += 3;
		}
		sprite.animation.frame = frame;
	}
	else if (name == "spike")
	{
		// spike frame
		uint frame_add = this.hasTag("bloody") && !g_kidssafe ? 1 : 0;
		bool is_hidden = this.get_u8("state") == Spike::hidden;
		
		this.getSprite().animation.frame = is_hidden ? 2 + frame_add: frame_add;
	}
}
