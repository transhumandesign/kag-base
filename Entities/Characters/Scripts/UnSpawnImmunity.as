void onInit(CBlob@ this)
{
	if (this.hasTag("invincibility done"))
	{
		return;
	}
	this.Tag("invincible");

	if (!this.exists("spawn immunity time"))
		this.set_u32("spawn immunity time", getGameTime());
}

void onTick(CBlob@ this)
{
	bool immunity = false;

	float time_modifier = (this.isKeyPressed(key_action1) ? 0.75f : 1.0f);

	u32 ticksSinceImmune = getGameTime() - this.get_u32("spawn immunity time");
	u32 maximumImmuneTicks = this.exists("custom immunity time") ? this.get_u32("custom immunity time") : (getRules().get_f32("immunity sec") * getTicksASecond() * time_modifier);
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
		this.Tag("invincibility done");
		this.Sync("invincibility done", true);

		this.getCurrentScript().runFlags |= Script::remove_after_this;
		this.getSprite().setRenderStyle(RenderStyle::normal);
	}
}
