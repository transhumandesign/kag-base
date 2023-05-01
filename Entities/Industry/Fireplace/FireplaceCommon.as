void Ignite(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	
	if (sprite is null) return;
	
	if (sprite.isAnimation("fire")) return;

	this.SetLight(true);
	this.Tag("fire source");

	sprite.SetAnimation("fire");
	sprite.SetEmitSoundPaused(false);
	sprite.PlaySound("/FireFwoosh.ogg");
	
	CSpriteLayer@ fire = sprite.getSpriteLayer("fire_animation_large");
	if (fire !is null)
	{
		fire.SetVisible(true);
	}
}