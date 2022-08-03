void onInit(CBlob@ this)
{
	this.Tag("invincible");
	this.set_s32("immunity ticks", getRules().get_f32("immunity sec") * getTicksASecond());
}

void onTick(CBlob@ this)
{
	if (!this.hasTag("invincible"))
	{
		return;
	}
	
	bool isImmune	= false;
	s32 immunity 	= this.get_s32("immunity ticks");
	
	if (immunity > 0)
	{
		// is immune, handle values
		isImmune = true;
		immunity -= (this.isKeyPressed(key_action1)) ? 2 : 1;
		this.set_s32("immunity ticks", Maths::Max(immunity, 0));
		
		// handle sprite
		CSprite@ s = this.getSprite();
		if (s !is null)
		{
			s.setRenderStyle(getGameTime() % 7 < 5 ? RenderStyle::normal : RenderStyle::additive);
			CSpriteLayer@ layer = s.getSpriteLayer("head");
			if (layer !is null)
				layer.setRenderStyle(getGameTime() % 7 < 5 ? RenderStyle::normal : RenderStyle::additive);
		}
	}
	
	if (!isImmune || this.getPlayer() is null)
	{
		//not immune anymore
		this.Untag("invincible");
		this.getSprite().setRenderStyle(RenderStyle::normal);
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}
