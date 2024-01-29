
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
		
		sprite.animation.frame = frame_add;
	
		// spiker spritelayer frame
		if (this.exists("spiker id"))
		{
			CBlob@ spiker = getBlobByNetworkID(this.get_u16("spiker id"));
			if (spiker !is null)
			{
				CSprite@ sprite = spiker.getSprite();
				
				if (sprite !is null)
				{
					CSpriteLayer@ layer = sprite.getSpriteLayer("background");
					if (layer !is null)
					{
						layer.animation.frame = frame_add;
					}
				}
			}
		}
	}
}
