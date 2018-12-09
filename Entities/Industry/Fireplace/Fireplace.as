// Fireplace

#include "ProductionCommon.as";
#include "Requirements.as"
#include "MakeFood.as"
#include "FireParticle.as"
#include "MakeDustParticle.as";
#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 9;
	this.getSprite().SetEmitSound("CampfireSound.ogg");
	this.getSprite().SetAnimation("fire");
	this.getSprite().SetFacingLeft(XORRandom(2) == 0);

	this.SetLight(true);
	this.SetLightRadius(164.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));

	this.Tag("fire source");
	//this.server_SetTimeToDie(60*3);
	this.getSprite().SetZ(-20.0f);

	this.addCommandID("extinguish");
}

void onTick(CBlob@ this)
{
	if (this.getSprite().isAnimation("fire"))
	{
		if (XORRandom(3) == 0)
		{
			makeSmokeParticle(this.getPosition(), -0.05f);

			this.getSprite().SetEmitSoundPaused(false);
		}
		else
			makeFireParticle(this.getPosition() + getRandomVelocity(90.0f, 3.0f, 360.0f));
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
	if (blob !is null)
	{
		if (blob.getName() == "fishy" && this.getSprite().isAnimation("fire"))
		{
			blob.getSprite().PlaySound("SparkleShort.ogg");
			CBlob@ food = server_MakeFood(blob.getPosition(), "Cooked Fish", 1);
			if (food !is null) {
				food.setVelocity(blob.getVelocity().opMul(0.5f));
			}
			blob.server_Die();
		}
	}
}

void onInit(CSprite@ this)
{
	this.SetZ(-50); //background

	//init flame layer
	CSpriteLayer@ fire = this.addSpriteLayer("fire_animation_large", "Entities/Effects/Sprites/LargeFire.png", 16, 16, -1, -1);

	if (fire !is null)
	{
		fire.SetRelativeZ(100);
		{
			Animation@ anim = fire.addAnimation("bigfire", 6, true);
			anim.AddFrame(1);
			anim.AddFrame(2);
			anim.AddFrame(3);
		}
		{
			Animation@ anim = fire.addAnimation("smallfire", 6, true);
			anim.AddFrame(4);
			anim.AddFrame(5);
			anim.AddFrame(6);
		}
		fire.SetVisible(true);
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

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::water)
	{
		Extinguish(this);
	}
	return damage;
}
