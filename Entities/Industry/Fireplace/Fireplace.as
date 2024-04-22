// Fireplace

#include "MakeFood.as";
#include "FireCommon.as";
#include "FireplaceCommon.as";
#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 9;
	this.getSprite().SetEmitSound("CampfireSound.ogg");
	this.getSprite().SetFacingLeft(XORRandom(2) == 0);
	
	this.SetLightRadius(164.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));
	
	SetFire(this, !this.hasTag("extinguished"));
}

void onTick(CBlob@ this)
{
	if (this.getSprite().isAnimation("fire"))
	{
		makeFireParticle(this.getPosition() + getRandomVelocity(90.0f, 3.0f, 90.0f));
	}

	if (this.isInWater())
	{
		Extinguish(this);
	}

	if (this.isInFlames())
	{
		Ignite(this);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;

	if (this.getSprite().isAnimation("fire"))
	{
		CBlob@ food = CookInFireplace(blob); // MakeFood.as
		if (food !is null)
		{
			food.setVelocity(blob.getVelocity().opMul(0.5f));
		}
	}
	else if (blob.hasTag("fire source")) //fire arrow works
	{
		Ignite(this);
	}
}

void onInit(CSprite@ this)
{
	this.SetZ(-50.0f);

	//init flame layer
	CSpriteLayer@ fire = this.addSpriteLayer("fire_animation_large", "Entities/Effects/Sprites/LargeFire.png", 16, 16, -1, -1);

	if (fire !is null)
	{
		fire.SetRelativeZ(1);
		fire.SetOffset(Vec2f(-2.0f, -6.0f));
		{
			Animation@ anim = fire.addAnimation("fire", 6, true);
			anim.AddFrame(1);
			anim.AddFrame(2);
			anim.AddFrame(3);
		}

		CBlob@ blob = this.getBlob();

		if (blob is null) return;

		fire.SetVisible(!blob.hasTag("extinguished"));
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isWaterHitter(customData)) 
	{
		Extinguish(this);
	}
	else if (isIgniteHitter(customData)) 
	{
		Ignite(this);
	}
	return damage;
}
