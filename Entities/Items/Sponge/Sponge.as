
#include "Hitters.as";
#include "SplashWater.as";

//config

//note: if you change this, change in runnerknock water stun as well
const int absorb_count = 100;
const string absorbed_prop = "absorbed";

//logic
void onInit(CBlob@ this)
{
	//todo: some tag-based keys to take interference (doesn't work on net atm)
	/*AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1 | key_action2 | key_action3);
	}*/

	this.getSprite().ReloadSprites(0, 0);
	this.set_u8(absorbed_prop, 0);

	this.getCurrentScript().runFlags |= Script::tick_inwater;

}

void onTick(CBlob@ this)
{
	if (!getNet().isServer())
	{
		//only run update on server
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}

	u8 absorbed = this.get_u8(absorbed_prop);

	if (absorbed < absorb_count)
	{
		Vec2f pos = this.getPosition();
		CMap@ map = this.getMap();
		f32 tilesize = map.tilesize;

		Vec2f[] vectors = {	pos,
		                    pos + Vec2f(0, -tilesize),
		                    pos + Vec2f(-tilesize, 0),
		                    pos + Vec2f(tilesize, 0),
		                    pos + Vec2f(0, tilesize)
		                  };

		for (uint i = 0; i < 5; i++)
		{
			Vec2f temp = vectors[i];
			if (map.isInWater(temp))
			{
				this.getCurrentScript().runFlags &= ~Script::tick_inwater; //tick always from now

				absorbed += 1;
				map.server_setFloodWaterWorldspace(temp, false);
				this.set_u8(absorbed_prop, absorbed);
				this.Sync(absorbed_prop, true);
			}
		}
	}
	else
	{
		this.server_SetTimeToDie(5.0f);
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}

}

void onDie(CBlob@ this)
{

}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{

}

//sprite

void onInit(CSprite@ this)
{
	this.getCurrentScript().tickFrequency = 15;
}

void onTick(CSprite@ this)
{
	u8 absorbed = this.getBlob().get_u8(absorbed_prop);
	this.animation.setFrameFromRatio(f32(absorbed) / absorb_count);
}
