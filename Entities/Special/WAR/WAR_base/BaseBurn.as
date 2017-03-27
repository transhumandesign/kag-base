//fire update for the base

#include "Hitters.as";
#include "FireCommon.as";

//global for the sake of simplicity
int tile_index = 0;

void onInit(CBlob@ this)
{
	this.set_s16(burn_duration , 200);
}

//void onTick ( CBlob@ this )
//{
//    if (!getNet().isServer()) { return; }
//
//    const u16 burn_time = this.getBurnTime();
//	if (burn_time < 30)
//	{
//		CMap@ map = this.getMap();
//		for (int i = 0; i < 5; i++)
//		{
//			tile_index++;
//			f32 ts = map.tilesize;
//			f32 half_ts = ts * 0.5f;
//			const int w = 14;
//			const int h = 7;
//			int this_index = (tile_index * 967) % (w * h);
//			Vec2f relpos = Vec2f(((this_index%w)-(w*0.5f)) , ((this_index/w)-(h*0.5f)));
//			Vec2f off_pos = (relpos * ts) + Vec2f(half_ts,half_ts);
//
//			if (map.isInFire(this.getPosition()+off_pos))
//			{
//				this.server_setFireOn();
//			}
//		}
//	}
//}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::burn)       // slow burn
	{
		damage *= 1.5f;
	}

	if (customData == Hitters::water)     // buckets of water
	{
		server_setFireOff(this);
	}

	return damage;
}

//sprite
int flame_sprite_count = 0;

void onInit(CSprite@ this)
{
	int count = 0;
	//floor sprites
	makeFlame(this, count++, Vec2f(0, 14) , 10.0f);
	makeFlame(this, count++, Vec2f(10, 15), 10.0f);
	makeFlame(this, count++, Vec2f(-10, 16), 10.0f);
	//tower sprites
	makeFlame(this, count++, Vec2f(0, -14) , 10.0f);
	makeFlame(this, count++, Vec2f(10, -12));
	makeFlame(this, count++, Vec2f(-10, -13), 10.0f);
	makeFlame(this, count++, Vec2f(20, -16));
	makeFlame(this, count++, Vec2f(30, -10));
	//nursery sprites
	makeFlame(this, count++, Vec2f(-25, -14), 10.0f);
	makeFlame(this, count++, Vec2f(-18, 8), 10.0f);
	makeFlame(this, count++, Vec2f(-35, -8), 10.0f);
	makeFlame(this, count++, Vec2f(-32, 0), 10.0f);
	flame_sprite_count = count;
}

CSpriteLayer@ makeFlame(CSprite@ this, int number, Vec2f offset, f32 relativeZ = 0.0f)
{
	CBlob@ blob = this.getBlob();
	const int blob_team = blob.getTeamNum();
	const int blob_skin = blob.getSkinNum();
	const string filename = CFileMatcher("/FireFlash.png").getFirst();
	CSpriteLayer@ flame = this.addSpriteLayer("flame_" + number, filename , 32, 32, blob_team, blob_skin);

	if (flame !is null)
	{
		Animation@ anim = flame.addAnimation("default", 2 + (number % 3), true);
		int frameoffset = XORRandom(7);

		for (int i = 0; i < 7; i++)
		{
			anim.AddFrame((i + frameoffset) % 7);
		}

		//tower_flame.SetVisible(false);
		flame.SetOffset(offset);
		flame.SetRelativeZ(relativeZ);
	}

	return flame;
}

void onTick(CSprite@ this)
{
	bool burning = (this.getBlob().get_s16(burn_timer) > 0);
	for (int step = 0; step < flame_sprite_count; ++step)
	{
		CSpriteLayer@ flame = this.getSpriteLayer("flame_" + step);

		if (flame !is null)
		{
			flame.SetVisible(burning);
		}
	}
	this.getBlob().SetLight(burning);
}
