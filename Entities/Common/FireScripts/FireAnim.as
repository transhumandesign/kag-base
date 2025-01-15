// Draw a flame sprite layer

#include "FireParticle.as";
#include "FireCommon.as";
#include "ParticlesCommon.as"

void onInit(CSprite@ this)
{
	//init flame layer
	CSpriteLayer@ fire = this.addSpriteLayer("fire_animation_large", "Entities/Effects/Sprites/LargeFire.png", 16, 16, -1, -1);

	if (fire !is null)
	{
		{
			Animation@ anim = fire.addAnimation("bigfire", 3, true);
			anim.AddFrame(1);
			anim.AddFrame(2);
			anim.AddFrame(3);
		}
		{
			Animation@ anim = fire.addAnimation("smallfire", 3, true);
			anim.AddFrame(4);
			anim.AddFrame(5);
			anim.AddFrame(6);
		}
		fire.SetVisible(false);
		fire.SetRelativeZ(10);
	}
	this.getCurrentScript().tickFrequency = 24;
}

void onTick(CSprite@ this)
{
    Random r(XORRandom(9999));
	this.getCurrentScript().tickFrequency = 8; // opt
	CBlob@ blob = this.getBlob();
	CSpriteLayer@ fire = this.getSpriteLayer("fire_animation_large");
	if (fire !is null)
	{
		//if we're burning
		if (blob.hasTag(burning_tag))
		{
			this.getCurrentScript().tickFrequency = 8;

			fire.SetVisible(true);

			//TODO: draw the fire layer with varying sizes based on var - may need sync spam :/
			//fire.SetAnimation( "bigfire" );
			fire.SetAnimation("smallfire");

			//set the "on fire" animation if it exists (eg wave arms around)
			if (this.getAnimation("on_fire") !is null && !blob.hasTag("dead"))
			{
				this.SetAnimation("on_fire");
			}

			MakeBasicLightParticle(
				blob.getPosition(),
				blob.getVelocity() * 0.2f + Vec2f(0.0f, -0.8f - r.NextFloat() * 0.8f),
				SColor(255, 120, 10, 0),
				0.94f,
				0.3f,
				40
			);
		}
		else
		{
			if (fire.isVisible())
			{
				this.PlaySound("/ExtinguishFire.ogg");
			}
			fire.SetVisible(false);
		}
	}
}
