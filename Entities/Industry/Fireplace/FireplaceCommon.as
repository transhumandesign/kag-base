void Ignite(CBlob@ this)
{
	if (this.getSprite().isAnimation("fire")) return;

	this.SetLight(true);
	this.Tag("fire source");

	this.getSprite().SetAnimation("fire");
	this.getSprite().SetEmitSoundPaused(false);
	this.getSprite().PlaySound("/FireFwoosh.ogg");
	
	CSpriteLayer@ fire = this.getSprite().getSpriteLayer("fire_animation_large");
	if (fire !is null)
	{
		fire.SetVisible(true);
	}
}