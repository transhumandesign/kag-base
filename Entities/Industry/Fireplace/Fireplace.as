// Fireplace

#include "ProductionCommon.as";
#include "Requirements.as";
#include "MakeFood.as";
#include "FireParticle.as";
#include "FireCommon.as";
#include "FireplaceCommon.as";
#include "Hitters.as";
#include "ParticlesCommon.as";

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 8;
	this.getSprite().SetEmitSound("CampfireSound.ogg");
	this.getSprite().SetEmitSoundPaused(false);
	this.getSprite().SetAnimation("fire");
	this.getSprite().SetFacingLeft(XORRandom(2) == 0);

	this.SetLight(true);
	this.SetLightRadius(250.0f);
	this.SetLightColor(SColor(255, 220, 40, 0));

	this.Tag("fire source");
	//this.server_SetTimeToDie(60*3);
	this.getSprite().SetZ(-20.0f);
}

void onTick(CBlob@ this)
{
	if (this.getSprite().isAnimation("fire"))
	{
		Vec2f variation = getRandomVelocity(90.0f, 5.0f, 90.0f);
		CParticle@ particle = makeFireParticle(this.getPosition() + Vec2f(0.0, 6.0f) + variation);

		if (particle !is null)
		{
			particle.velocity.x -= variation.x * 0.03;
			particle.velocity.y -= 0.2f;
			particle.gravity.y *= 0.5f;
			// particle.framestep *= 2;
		}
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
		CBlob@ food = cookFood(blob);
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
	this.SetZ(-50); //background

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
		fire.SetVisible(true);
	}
}

void onTick(CSprite@ this)
{
	if (getGameTime() % 2 == 0 && this.isAnimation("fire"))
	{
		Random r(XORRandom(9999));

		CParticle@ light = MakeBasicLightParticle(
			this.getBlob().getPosition() + Vec2f((r.NextFloat() - 0.5f) * 16.0f, (r.NextFloat() - 0.5f) * 16.0f),
			Vec2f((r.NextFloat() - 0.5f) * 2.0f, -2.0f - (r.NextFloat() - 0.5f) * 1.0f),
			SColor(255, 120, 30, 25),
			0.95f,
			0.3f + r.NextFloat() * 0.2f,
			30
		);
	}
}

void Extinguish(CBlob@ this)
{
	if (this.getSprite().isAnimation("nofire")) return;

	this.SetLight(false);
	this.Untag("fire source");

	this.getSprite().SetAnimation("nofire");
	this.getSprite().SetEmitSoundPaused(true);
	this.getSprite().PlaySound("/ExtinguishFire.ogg");
	
	CSpriteLayer@ fire = this.getSprite().getSpriteLayer("fire_animation_large");
	if (fire !is null)
	{
		fire.SetVisible(false);
	}
	
	makeSmokeParticle(this.getPosition()); //*poof*
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