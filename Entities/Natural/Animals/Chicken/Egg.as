#include "KnockedCommon.as"

const int grow_time = 50 * getTicksASecond();

const int MAX_CHICKENS_TO_HATCH = 5;
const f32 CHICKEN_LIMIT_RADIUS = 120.0f;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 120;
	this.addCommandID("hatch");
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return true;
}

void onTick(CBlob@ this)
{
	if (getNet().isServer() && this.getTickSinceCreated() > grow_time)
	{
		int chickenCount = 0;
		CBlob@[] blobs;
		this.getMap().getBlobsInRadius(this.getPosition(), CHICKEN_LIMIT_RADIUS, @blobs);
		for (uint step = 0; step < blobs.length; ++step)
		{
			CBlob@ other = blobs[step];
			if (other.getName() == "chicken")
			{
				chickenCount++;
			}
		}

		if (chickenCount < MAX_CHICKENS_TO_HATCH)
		{
			this.SendCommand(this.getCommandID("hatch"));
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("hatch"))
	{
		BreakEgg(this);
	
		if (isServer())
		{			
			server_CreateBlob("chicken", -1, this.getPosition() + Vec2f(0, -5.0f));
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point)
{
	if (this.getShape().vellen <= 6.8f)
		return;

	// throwing egg too hard on the ground breaks it
	if (solid)
	{
		BreakEgg(this);
	}
	
	// throw egg at enemies to mini-stun them
	if 	(blob !is null 
		&& blob.hasTag("player")
		&& this.getTeamNum() != blob.getTeamNum())
	{
		BreakEgg(this);
		blob.Tag("dazzled");
		setKnocked(blob, 10, true);
		Sound::Play("/ArgShort", blob.getPosition());
	}
}

void BreakEgg(CBlob@ this)
{
	CSprite@ s = this.getSprite();
	if (s !is null)
	{
		s.Gib();
		s.PlaySound("/EggCrack" + XORRandom(2) + ".ogg");
	}
	if (isServer())
	{
		this.server_SetHealth(-1);
		this.server_Die();
	}
}
