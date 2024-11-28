//drowning for all characters

#include "/Entities/Common/Attacks/Hitters.as"

//config vars

const int FREQ = 6; //must be >2 or breathing at top of water breaks
const u8 default_aircount = 180; //6s, remember to update runnerhoverhud.as

void onInit(CBlob@ this)
{
	this.set_u8("air_count", default_aircount);
	this.getCurrentScript().removeIfTag = "dead";
	this.getCurrentScript().tickFrequency = FREQ; // opt
}

void onTick(CBlob@ this)
{
	// TEMP: don't drown migrants, its annoying
	if (this.getShape().isStatic())
		return;

	Vec2f pos = this.getPosition();
	const bool inwater = this.isInWater() && this.getMap().isInWater(pos + Vec2f(0.0f, -this.getRadius() * 0.66f));

	u8 aircount = this.get_u8("air_count");
	this.getCurrentScript().tickFrequency = FREQ;

	if (isServer())
	{

		if (inwater && !this.hasTag("invincible"))
		{
			if (aircount >= FREQ)
			{
				aircount -= FREQ;
			}

			//drown damage
			if (aircount < FREQ)
			{
				this.server_Hit(this, pos, Vec2f(0, 0), 0.5f, Hitters::drown, true);
				aircount += 30;
			}
		}
		else
		{
			if (aircount < default_aircount/2)
			{
				aircount = default_aircount/2;
			}
			else if (aircount < default_aircount)
			{
				if (this.isOnGround() || this.isOnLadder())
				{
					aircount += FREQ * 2;
				}
				else
				{
					aircount += FREQ;
				}
			}
			else
			{
				aircount = default_aircount;
			}
		}

		if (aircount != this.get_u8("air_count"))
		{
			this.set_u8("air_count", aircount);
			this.Sync("air_count", true);
		}
	}

	if (isClient()) // sound control
	{
		aircount -= 6; // -6 since the lowest value we every get from the server is 6 (which means no sound plays)
		
		if (inwater)
		{
			if (this.hasTag("gasping"))
			{
				this.Untag("gasping");
			}

			if (aircount < FREQ)
			{
				Sound::Play("Gurgle", pos, 2.0f);
			}
		}
		else
		{
			if(aircount < default_aircount/2 && !this.hasTag("gasping"))
			{
				this.Tag("gasping");
				Sound::Play("Sounds/gasp.ogg", pos, 3.0f);
			}
		}
	}
}

// SPRITE renders in party indicator