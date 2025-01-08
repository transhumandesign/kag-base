
#include "FireParticle.as";

void Ignite(CBlob@ this)
{
	if (this.hasTag("fire source")) return;

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.PlaySound("/FireFwoosh.ogg");
	}

	SetFire(this, true);
}

void Extinguish(CBlob@ this)
{
	if (!this.hasTag("fire source")) return;

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		this.getSprite().PlaySound("/ExtinguishFire.ogg");
	}

	makeBigSmokeParticle(this.getPosition()); //*poof*

	SetFire(this, false);
}

void SetFire(CBlob@ this, bool fire_on)
{
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.SetEmitSoundPaused(!fire_on);
	this.SetLight(fire_on);
	
	if (fire_on)
	{
		this.Tag("fire source");
		this.Untag("extinguished");
		sprite.SetAnimation("fire");
	}
	else
	{
		this.Untag("fire source");
		this.Tag("extinguished");
		sprite.SetAnimation("nofire");
	}
	
	CSpriteLayer@ fire = sprite.getSpriteLayer("fire_animation_large");
	if (fire !is null)
	{
		fire.SetVisible(fire_on);
	}
}
