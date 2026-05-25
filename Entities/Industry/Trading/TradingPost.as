// Trading Post

#include "MakeDustParticle.as";

Random traderRandom(Time());

void onInit(CBlob@ this)
{
	this.getShape().getConsts().mapCollisions = false;
	this.set_Vec2f("nobuild extend", Vec2f(0.0f, 8.0f));
	CSprite@ sprite = this.getSprite();

	if (sprite !is null)
	{
		sprite.SetZ(-50.0f);   // push to background
		u8 trader_sex_num = this.getNetworkID() % 2;
		string sex = (trader_sex_num == 0) ? "TraderMale.png" : "TraderFemale.png";
		this.set_u8("trader sex num", trader_sex_num);
		CSpriteLayer@ trader = sprite.addSpriteLayer("trader", sex, 16, 16, 0, 0);
		trader.SetRelativeZ(20);
		Animation@ stop = trader.addAnimation("stop", 1, false);
		stop.AddFrame(0);
		Animation@ walk = trader.addAnimation("walk", 1, false);
		walk.AddFrame(0); walk.AddFrame(1); walk.AddFrame(2); walk.AddFrame(3);
		walk.time = 10;
		walk.loop = true;
		trader.SetOffset(Vec2f(0, 8));
		trader.SetFrame(0);
		trader.SetAnimation(stop);
		trader.SetIgnoreParentFacing(true);
		this.set_bool("trader moving", false);
		this.set_bool("moving left", false);
		this.set_u32("move timer", getGameTime() + (traderRandom.NextRanged(5) + 5)*getTicksASecond());
		this.set_u32("next offset", traderRandom.NextRanged(16));
	}
	//TODO: set shop type and spawn trader based on some property
}


//Sprite updates

void onTick(CSprite@ this)
{
	//TODO: empty? show it.
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	
	CSpriteLayer@ trader = this.getSpriteLayer("trader");
	bool trader_moving = blob.get_bool("trader moving");
	bool moving_left = blob.get_bool("moving left");
	u32 move_timer = blob.get_u32("move timer");
	u32 next_offset = blob.get_u32("next offset");
	
	if (!trader_moving)
	{
		if (move_timer <= getGameTime())
		{
			blob.set_bool("trader moving", true);
			trader.SetAnimation("walk");
			trader.SetFacingLeft(!moving_left);
			Vec2f offset = trader.getOffset();
			offset.x *= -1.0f;
			trader.SetOffset(offset);

		}

	}
	else
	{
		//had to do some weird shit here because offset is based on facing
		Vec2f offset = trader.getOffset();
		if (moving_left && offset.x > -next_offset)
		{
			offset.x -= 0.5f;
			trader.SetOffset(offset);
		}
		else if (moving_left && offset.x <= -next_offset)
		{
			blob.set_bool("trader moving", false);
			blob.set_bool("moving left", false);
			blob.set_u32("move timer", getGameTime() + (traderRandom.NextRanged(5) + 5)*getTicksASecond());
			blob.set_u32("next offset", traderRandom.NextRanged(16));
			trader.SetAnimation("stop");
		}
		else if (!moving_left && offset.x > -next_offset)
		{
			offset.x -= 0.5f;
			trader.SetOffset(offset);
		}
		else if (!moving_left && offset.x <= -next_offset)
		{
			blob.set_bool("trader moving", false);
			blob.set_bool("moving left", true);
			blob.set_u32("move timer", getGameTime() + (traderRandom.NextRanged(5) + 5)*getTicksASecond());
			blob.set_u32("next offset", traderRandom.NextRanged(16));
			trader.SetAnimation("stop");
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getTeamNum() == this.getTeamNum() && hitterBlob !is this)
	{
		return 0.0f;
	} //no griffing

	this.Damage(damage, hitterBlob);
	
	return 0.0f;
}


void onHealthChange(CBlob@ this, f32 oldHealth)
{
	// destructible in TDM and Sandbox only
	CRules@ rules = getRules();
	bool TDM = rules.gamemode_name == "Team Deathmatch";
	bool SBX = rules.gamemode_name == "Sandbox";
	
	if (!isServer() || !(TDM || SBX))
		return;

	if (oldHealth > 0.0f && this.getHealth() <= 0.0f)
	{
		// spawn trader that can be killed
		if (this.exists("trader sex num"))
		{
			CBlob@ trader = server_CreateBlobNoInit("trader");
			if (trader !is null)
			{
				trader.set_u8("sex num", this.get_u8("trader sex num"));
				trader.setPosition(this.getPosition());
				trader.Init();
			}
		}
	
		// destroy building
		this.server_Die();
	}
}

void onDie(CBlob@ this)
{
	MakeDustParticle(this.getPosition(), "Smoke.png");
		
	CSprite@ sprite = this.getSprite();
	sprite.PlaySound("/BuildingExplosion");
	sprite.Gib();
}