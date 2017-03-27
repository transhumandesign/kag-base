// Trader logic

#include "RunnerCommon.as"
#include "Help.as";

#include "Hitters.as";

#include "TraderWantedList.as";

//trader methods

//blob

void onInit(CBlob@ this)
{
	//no spinning
	this.getShape().SetRotationsAllowed(false);
	this.set_f32("gib health", -1.5f);
	this.Tag("flesh");
	this.getBrain().server_SetActive(true);

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_moving;

	//EnsureWantedList();
}

void onReload(CSprite@ this)
{
	this.getConsts().filename = this.getBlob().getSexNum() == 0 ?
	                            "Entities/Special/WAR/Trading/TraderMale.png" :
	                            "Entities/Special/WAR/Trading/TraderFemale.png";
}

void onGib(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	CParticle@ Gib1     = makeGibParticle("Entities/Special/WAR/Trading/TraderGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall");
	CParticle@ Gib2     = makeGibParticle("Entities/Special/WAR/Trading/TraderGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall");
	CParticle@ Gib3     = makeGibParticle("Entities/Special/WAR/Trading/TraderGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 2, 0, Vec2f(16, 16), 2.0f, 0, "/BodyGibFall");
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	if (this.getHealth() < 1.0f && !this.hasTag("dead"))
	{
		this.Tag("dead");
		this.server_SetTimeToDie(20);
	}

	if (this.getHealth() < 0)
	{
		this.getSprite().Gib();
		this.server_Die();
		return;
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	if (byBlob.getTeamNum() != this.getTeamNum())
		return true;

	CBlob@[] blobsInRadius;
	if (this.getMap().getBlobsInRadius(this.getPosition(), 0.0f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b.getName() == "tradingpost")
			{
				return false;
			}
		}
	}
	return true;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	// dont collide with people
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob !is this && getMap().isBlobInRadius("tradingpost", this.getPosition(), 32.0f))
	{
		return 0.0f;
	}
	return damage;
}


//sprite/anim update

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	// set dead animations

	if (blob.hasTag("dead"))
	{
		if (!this.isAnimation("dead"))
			this.PlaySound("/TraderScream");

		this.SetAnimation("dead");

		if (blob.isOnGround())
		{
			this.SetFrameIndex(0);
		}
		else
		{
			this.SetFrameIndex(1);
		}
		//this.getCurrentScript().runFlags |= Script::remove_after_this;

		return;
	}

	if (blob.hasTag("shoot wanted"))
	{
		this.SetAnimation("shoot");
		return;
	}

	// set animations
	Vec2f pos = blob.getPosition();
	Vec2f aimpos = blob.getAimPos();
	bool ended = this.isAnimationEnded();

	if ((blob.isKeyPressed(key_left) || blob.isKeyPressed(key_right)) ||
	        (blob.isOnLadder() && (blob.isKeyPressed(key_up) || blob.isKeyPressed(key_down))))
	{
		this.SetAnimation("walk");
	}
	else if (ended)
	{
		this.SetAnimation("default");
	}
}
