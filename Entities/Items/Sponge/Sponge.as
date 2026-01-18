#include "Hitters.as";
#include "SpongeCommon.as";

const u8 DRY_COOLDOWN = 8;

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
	this.set_u8(ABSORBED_PROP, 0);
	this.set_u8("cooldown_time", 0);

	this.Tag("pushedByDoor");
	this.getCurrentScript().runFlags |= Script::tick_not_ininventory;
}

void onTick(CBlob@ this)
{
	u8 absorbed = this.get_u8(ABSORBED_PROP);
	Vec2f pos = this.getPosition();
	CMap@ map = this.getMap();
	f32 tilesize = map.tilesize;

	//absorb water
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
			if (absorbed < ABSORB_COUNT)
			{
				absorbed = adjustAbsorbedAmount(this, 1);
				map.server_setFloodWaterWorldspace(temp, false);
			}
				
			this.set_u32(ABSORBED_TIME, getGameTime());
		}
	}
	
	//dry out sponge
	if (absorbed > 0)
	{
		if (this.isInFlames()) //in flames
		{
			absorbed = adjustAbsorbedAmount(this, -1);
		}
		else if (this.get_u8("cooldown_time") == 0) //near fireplace
		{
			CBlob@[] blobsInRadius;
			if (map.getBlobsInRadius(pos, 8.0f, @blobsInRadius))
			{
				for (uint i = 0; i < blobsInRadius.length; i++)
				{
					CBlob @blob = blobsInRadius[i];
					if (blob.getName() == "fireplace")
					{
						CSprite@ sprite = blob.getSprite();
						if (sprite !is null && sprite.isAnimation("fire"))
						{
							absorbed = adjustAbsorbedAmount(this, -1);
							this.set_u8("cooldown_time", DRY_COOLDOWN);
							break;
						}
					}
				}
			}
		}
	}
	
	//reduce cooldown time
	if (this.get_u8("cooldown_time") > 0)
	{
		this.add_u8("cooldown_time", -1);
	}
}

//sprite

void onInit(CSprite@ this)
{
	this.getCurrentScript().tickFrequency = 15;
}

void onTick(CSprite@ this)
{
	u8 absorbed = this.getBlob().get_u8(ABSORBED_PROP);
	spongeUpdateSprite(this, absorbed);
}

u8 adjustAbsorbedAmount(CBlob@ this, f32 amount)
{
	u8 absorbed = this.get_u8(ABSORBED_PROP);
	absorbed = Maths::Clamp(absorbed + amount, 0, ABSORB_COUNT);
	this.set_u8(ABSORBED_PROP, absorbed);
	this.Sync(ABSORBED_PROP, true);
	return absorbed;
}


// custom gibs
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.05f) //sound for all damage
	{
		f32 angle = (this.getPosition() - worldPoint).getAngle();
		if (hitterBlob !is this)			
		{
			this.getSprite().PlayRandomSound("/Wetfall2", Maths::Min(1.25f, Maths::Max(0.5f, damage)));
		} 
		else 
		{
			angle = 90.0f; // self-hit. spawn gibs upwards
		}

		makeGibParticle("Entities/Items/Sponge/SpongeGibs.png", 
			worldPoint, getRandomVelocity(angle, 1.0f + damage, 90.0f) + Vec2f(0.0f, -2.0f),
	                0, 4 + XORRandom(4), 
	                Vec2f(8, 8), 2.0f, 0, "", 0);

	}

	return damage;
}