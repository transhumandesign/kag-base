// Fireplace
//todo: don't fuel fireplace when you throw the fireplace into logs

#include "ProductionCommon.as";
#include "Requirements.as";
#include "MakeFood.as";
#include "FireParticle.as";
#include "Hitters.as";

const float BURN_RATE = 0.4f;
const int FUEL_POTENCY = 10;
const int MAX_BURN_TIME = 100;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 10;
	this.getSprite().SetEmitSound("CampfireSound.ogg");
	this.getSprite().SetAnimation("nofire");
	this.getSprite().SetFacingLeft(XORRandom(2) == 0);

	this.SetLight(false);
	this.SetLightRadius(164.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));

	this.Tag("fire source");
	this.getSprite().SetZ(-20.0f);

	if (this.getTeamNum() != 255)
	{
		this.set_f32("fire time", 0);
	}
	else
	{
		this.set_f32("fire time", MAX_BURN_TIME);
	}

	this.addCommandID("extinguish");
}

void onTick(CBlob@ this)
{
	if (this.getSprite().isAnimation("fire"))
	{
		makeFireParticle(this.getPosition() + getRandomVelocity(90.0f, 3.0f, 90.0f));
	}

	if (this.get_f32("fire time") > 0)
	{
		Ignite(this);

		if (this.getTeamNum() != 255)
		{
			f32 fireTime = Maths::Max(this.get_f32("fire time") - BURN_RATE, 0);
			this.set_f32("fire time", fireTime);
		}
	}
	else
	{
		Extinguish(this);
	}

	if (this.isInWater())
	{
		Extinguish(this);
	}

	if (this.isInFlames())
	{
		Ignite(this);
		f32 fireTime = Maths::Max(this.get_f32("fire time"), MAX_BURN_TIME / 2);
		this.set_f32("fire time", fireTime);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		if (this.getSprite().isAnimation("fire"))
		{
			CBlob@ food = cookFood(blob);
			if (food !is null)
			{
				food.setVelocity(blob.getVelocity().opMul(0.5f));
			}
		}

		if (blob.getName() == "log")
		{
			f32 fireTime = Maths::Min(this.get_f32("fire time") + FUEL_POTENCY, MAX_BURN_TIME);
			this.set_f32("fire time", fireTime);
			blob.server_Die();
			blob.getSprite().PlaySound("SparkleShort.ogg");
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
		fire.SetRelativeZ(1);
		fire.SetOffset(Vec2f(-2.0f, -6.0f));
		{
			Animation@ anim = fire.addAnimation("fire", 6, true);
			anim.AddFrame(1);
			anim.AddFrame(2);
			anim.AddFrame(3);
		}
		fire.SetVisible(false);
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

	this.set_f32("fire time", 0);
	
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

bool canBePickedUp(CBlob@ this, CBlob@ blob)
{
	return this.getSprite().isAnimation("nofire");
}
