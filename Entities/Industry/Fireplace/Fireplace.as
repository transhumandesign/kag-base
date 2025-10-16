// Fireplace

#include "MakeFood.as";
#include "FireCommon.as";
#include "FireplaceCommon.as";
#include "Hitters.as";
#include "ParticlesCommon.as";

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 8;

	this.SetLight(true);
	this.SetLightRadius(250.0f);
	this.SetLightColor(SColor(255, 220, 40, 0));

	SetFire(this, !this.hasTag("extinguished"));

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("CampfireSound.ogg");
		sprite.SetFacingLeft(XORRandom(2) == 0);
	}
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
