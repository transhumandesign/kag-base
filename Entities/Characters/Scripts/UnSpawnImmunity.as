void onInit(CBlob@ this)
{
	this.Tag("invincible");

	if (!this.exists("spawn immunity time"))
		this.set_u32("spawn immunity time", getGameTime());
}

void onTick(CBlob@ this)
{
	bool immunity = false;

	float time_modifier = (this.isKeyPressed(key_action1) ? 0.75f : 1.0f);

	u32 ticksSinceImmune = getGameTime() - this.get_u32("spawn immunity time");
	u32 maximumImmuneTicks = getRules().get_f32("immunity sec") * getTicksASecond() * time_modifier;
	if (ticksSinceImmune < maximumImmuneTicks)
	{
		CSprite@ s = this.getSprite();
		if (s !is null)
		{
			s.setRenderStyle(getGameTime() % 7 < 5 ? RenderStyle::normal : RenderStyle::additive);
			CSpriteLayer@ layer = s.getSpriteLayer("head");
			if (layer !is null)
				layer.setRenderStyle(getGameTime() % 7 < 5 ? RenderStyle::normal : RenderStyle::additive);
		}
		immunity = true;
	}

	if (!immunity || this.getPlayer() is null)
	{
		this.Untag("invincible");
		this.getCurrentScript().runFlags |= Script::remove_after_this;
		this.getSprite().setRenderStyle(RenderStyle::normal);
	}
}
