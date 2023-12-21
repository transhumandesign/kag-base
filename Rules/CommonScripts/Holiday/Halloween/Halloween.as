// Halloween.as
#include "HolidayCommon.as";

Random spawnRand(Time());

const s32 greg_interval = 25*60*getTicksASecond(); //every 25 minutes 50/50 spawn gregs

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	getMap().SetDayTime(0.85);
	if (!this.exists("greg time"))
		this.set_s32("greg time", greg_interval); //30 minutes

	if (!this.exists(holiday_head_prop))
		this.set_u8(holiday_head_prop, 73);

	this.addCommandID("necrolaugh");
}

void onPlayerDie( CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData )
{
	if (victim is null)
	{
		return;
	}

	CBlob@ blob = victim.getBlob();

	if (blob is null)
	{
		return;
	}

	ParticleAnimated(
	"spirit.png",                   // file
	blob.getPosition(),             // position
	Vec2f(0, -0.25),                // velocity
	0,                              // angle
	1.0f,                           // scale
	8,                              // ticks per frame
	0.0f,                           // gravity
	true);                          // self lit

	blob.getSprite().PlaySound("WraithSpawn.ogg");
}

void onTick(CRules@ this)
{
	if (isServer())
	{
		s32 greg_time = this.get_s32("greg time");
		greg_time--;
		this.set_s32("greg time", greg_time);

		if (this.getCurrentState() != 2)
			return;

		if (greg_time <= 0)
		{
			if (spawnRand.Next() % 2 == 0)
			{
				CBitStream bt;
				this.SendCommand(this.getCommandID("necrolaugh"), bt);
				Vec2f spawnPos(getMap().tilemapwidth*8.0f/2.0f, 32.0f);
				
				int players = getPlayersCount();
				players /= 2;
				players += 6;
				for(int i = 0; i < players; i++)
				{
					server_CreateBlob("greg", 255, spawnPos);
				}
			}
			this.set_s32("greg time", greg_interval);
		}
	}
}

void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("necrolaugh") && isClient())
	{
		Vec2f spawnPos(getMap().tilemapwidth*8.0f/2.0f, 32.0f);
		Sound::Play("EvilLaughShort1.ogg");
		ParticleZombieLightning(spawnPos);
	}
}
