
//script for a chicken

#include "AnimalConsts.as";

const u8 DEFAULT_PERSONALITY = SCARED_BIT;
const int MAX_EGGS = 2; //maximum symultaneous eggs
const int MAX_CHICKENS = 6;
const f32 CHICKEN_LIMIT_RADIUS = 120.0f;

int g_lastSoundPlayedTime = 0;
int g_layEggInterval = 0;

//sprite

void onInit(CSprite@ this)
{
	this.ReloadSprites(0, 0); //always blue

}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	if (!blob.hasTag("dead"))
	{
		f32 x = Maths::Abs(blob.getVelocity().x);
		if (blob.isAttached())
		{
			AttachmentPoint@ ap = blob.getAttachmentPoint(0);
			if (ap !is null && ap.getOccupied() !is null)
			{
				if (Maths::Abs(ap.getOccupied().getVelocity().y) > 0.2f)
				{
					this.SetAnimation("fly");
				}
				else
					this.SetAnimation("idle");
			}
		}
		else if (!blob.isOnGround())
		{
			this.SetAnimation("fly");
		}
		else if (x > 0.02f)
		{
			this.SetAnimation("walk");
		}
		else
		{
			if (this.isAnimationEnded())
			{
				uint r = XORRandom(20);
				if (r == 0)
					this.SetAnimation("peck_twice");
				else if (r < 5)
					this.SetAnimation("peck");
				else
					this.SetAnimation("idle");
			}
		}
	}
	else
	{
		this.SetAnimation("dead");
		this.getCurrentScript().runFlags |= Script::remove_after_this;
		this.PlaySound("/ScaredChicken");
	}
}

//blob

void onInit(CBlob@ this)
{
	this.set_f32("bite damage", 0.25f);

	//brain
	this.set_u8(personality_property, DEFAULT_PERSONALITY);
	this.getBrain().server_SetActive(true);
	this.set_f32(target_searchrad_property, 30.0f);
	this.set_f32(terr_rad_property, 75.0f);
	this.set_u8(target_lose_random, 14);

	//for shape
	this.getShape().SetRotationsAllowed(false);

	//for flesh hit
	this.set_f32("gib health", -0.0f);
	this.Tag("flesh");

	this.getShape().SetOffset(Vec2f(0, 6));

	this.getCurrentScript().runFlags |= Script::tick_blob_in_proximity;
	this.getCurrentScript().runProximityTag = "player";
	this.getCurrentScript().runProximityRadius = 320.0f;

	// attachment

	//todo: some tag-based keys to take interference (doesn't work on net atm)
	/*AttachmentPoint@ att = this.getAttachments().getAttachmentPointByName("PICKUP");
	att.SetKeysToTake(key_action1);*/

	// movement

	AnimalVars@ vars;
	if (!this.get("vars", @vars))
		return;
	vars.walkForce.Set(1.0f, -0.1f);
	vars.runForce.Set(2.0f, -1.0f);
	vars.slowForce.Set(1.0f, 0.0f);
	vars.jumpForce.Set(0.0f, -20.0f);
	vars.maxVelocity = 1.1f;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return true; //maybe make a knocked out state? for loading to cata?
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !blob.hasTag("flesh");
}

void onTick(CBlob@ this)
{
	f32 x = this.getVelocity().x;
	if (Maths::Abs(x) > 1.0f)
	{
		this.SetFacingLeft(x < 0);
	}
	else
	{
		if (this.isKeyPressed(key_left))
		{
			this.SetFacingLeft(true);
		}
		if (this.isKeyPressed(key_right))
		{
			this.SetFacingLeft(false);
		}
	}

	if (this.isAttached())
	{
		AttachmentPoint@ att = this.getAttachmentPoint(0);   //only have one
		if (att !is null)
		{
			CBlob@ b = att.getOccupied();
			if (b !is null)
			{
				// too annoying

				//if (g_lastSoundPlayedTime+20+XORRandom(10) < getGameTime())
				//{
				//	if(XORRandom(2) == 1)
				//		this.getSprite().PlaySound("/ScaredChicken");
				//	else
				//		this.getSprite().PlaySound("/Pluck");
				//
				//	g_lastSoundPlayedTime = getGameTime();
				//}

				Vec2f vel = b.getVelocity();
				if (vel.y > 0.5f)
				{
					b.AddForce(Vec2f(0, -20));
				}
			}
		}
	}
	else if (!this.isOnGround())
	{
		Vec2f vel = this.getVelocity();
		if (vel.y > 0.5f)
		{
			this.AddForce(Vec2f(0, -10));
		}
	}
	else if (XORRandom(128) == 0 && g_lastSoundPlayedTime + 30 < getGameTime())
	{
		this.getSprite().PlaySound("/Pluck");
		g_lastSoundPlayedTime =  getGameTime();

		// lay eggs
		if (getNet().isServer())
		{
			g_layEggInterval++;
			if (g_layEggInterval % 13 == 0)
			{
				Vec2f pos = this.getPosition();
				bool otherChicken = false;
				int eggsCount = 0;
				int chickenCount = 0;
				string name = this.getName();
				CBlob@[] blobs;
				this.getMap().getBlobsInRadius(pos, CHICKEN_LIMIT_RADIUS, @blobs);
				for (uint step = 0; step < blobs.length; ++step)
				{
					CBlob@ other = blobs[step];
					if (other is this)
						continue;

					const string otherName = other.getName();
					if (otherName == name)
					{
						if (this.getDistanceTo(other) < 32.0f)
						{
							otherChicken = true;
						}
						chickenCount++;
					}
					if (otherName == "egg")
					{
						eggsCount++;
					}
				}

				if (otherChicken && eggsCount < MAX_EGGS && chickenCount < MAX_CHICKENS)
				{
					server_CreateBlob("egg", this.getTeamNum(), this.getPosition() + Vec2f(0.0f, 5.0f));
				}
			}
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob is null)
		return;

	if (blob.getRadius() > this.getRadius() && g_lastSoundPlayedTime + 25 < getGameTime() && blob.hasTag("flesh"))
	{
		this.getSprite().PlaySound("/ScaredChicken");
		g_lastSoundPlayedTime = getGameTime();
	}
}

