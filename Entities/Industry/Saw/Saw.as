// Saw logic

#include "Hitters.as"
#include "GenericButtonCommon.as"
#include "ParticleSparks.as"

const string toggle_id = "toggle_power";
const string sawteammate_id = "sawteammate";

void onInit(CBlob@ this)
{
	this.Tag("saw");

	this.addCommandID(toggle_id);
	this.addCommandID(sawteammate_id);

	SetSawOn(this, true);
}

//toggling on/off

void SetSawOn(CBlob@ this, const bool on)
{
	this.set_bool("saw_on", on);
}

bool getSawOn(CBlob@ this)
{
	return this.get_bool("saw_on");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (caller.getTeamNum() != this.getTeamNum() || this.getDistanceTo(caller) > 16) return;

	string desc = getTranslatedString("Turn Saw " + (getSawOn(this) ? "Off" : "On"));
	caller.CreateGenericButton(8, Vec2f(0, 0), this, this.getCommandID(toggle_id), desc);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID(sawteammate_id))
	{
		CBlob@ tobeblended = getBlobByNetworkID(params.read_netid());
		if (tobeblended !is null)
		{
			tobeblended.Tag("sawed");

			CSprite@ s = tobeblended.getSprite();
			if (s !is null)
			{
				s.Gib();
			}
		}

		this.getSprite().PlaySound("SawOther.ogg");
		cmd = this.getCommandID(toggle_id);	// proceed with toggle_id stuff
	}

	if (cmd == this.getCommandID(toggle_id))
	{
		bool set = !getSawOn(this);
		SetSawOn(this, set);

		if (getNet().isClient()) //closed/opened gfx
		{
			CSprite@ sprite = this.getSprite();

			u8 frame = set ? 0 : 1;

			sprite.animation.frame = frame;

			CSpriteLayer@ back = sprite.getSpriteLayer("back");
			if (back !is null)
			{
				back.animation.frame = frame;
			}

			CSpriteLayer@ chop = sprite.getSpriteLayer("chop");
			if (chop !is null)
			{
				chop.SetOffset(Vec2f());
			}
		}
	}
}

//function for blending things
void Blend(CBlob@ this, CBlob@ tobeblended)
{
	if (this is tobeblended || tobeblended.hasTag("sawed") ||
	        tobeblended.hasTag("invincible") || !getSawOn(this))
	{
		return;
	}

	tobeblended.Tag("sawed");

	if ((tobeblended.getName() == "waterbomb" || tobeblended.getName() == "bomb") && tobeblended.hasTag("activated"))
		return;

	//make plankfrom wooden stuff
	string blobname = tobeblended.getName();
	if (blobname == "log" || blobname == "crate")
	{
		if (getNet().isServer())
		{
			CBlob@ blob = server_CreateBlobNoInit('mat_wood');

			if (blob !is null)
			{
				blob.Tag('custom quantity');
				blob.Init();

				blob.setPosition(this.getPosition());
				blob.setVelocity(Vec2f(0, -4.0f));
				blob.server_SetQuantity(50);
			}
		}

		this.getSprite().PlaySound("SawLog.ogg");
	}
	else
	{
		this.getSprite().PlaySound("SawOther.ogg");
	}

	// on saw player or dead body - disable the saw
	if (
		(tobeblended.getPlayer() !is null || //player
		(tobeblended.hasTag("flesh") && tobeblended.hasTag("flesh"))) && //dead body
		tobeblended.getTeamNum() == this.getTeamNum()) //same team as saw
	{
		CBitStream params;
		params.write_netid(tobeblended.getNetworkID());
		this.SendCommand(this.getCommandID(sawteammate_id), params);
	}
	
	CSprite@ s = tobeblended.getSprite();
	if (s !is null)
	{
		s.Gib();
	}

	//give no fucks about teamkilling
	tobeblended.server_SetHealth(-1.0f);
	tobeblended.server_Die();
}


bool canSaw(CBlob@ this, CBlob@ blob)
{
	if (blob.getRadius() >= this.getRadius() * 0.99f || blob.getShape().isStatic() ||
	        blob.hasTag("sawed") || blob.hasTag("invincible"))
	{
		return false;
	}

	string name = blob.getName();

	if (
	    name == "migrant" ||
	    name == "wooden_door" ||
	    name == "mat_wood" ||
	    name == "tree_bushy" ||
	    name == "tree_pine" ||
	    (name == "mine" && blob.getTeamNum() == this.getTeamNum()))
	{
		return false;
	}

	//flesh blobs have to be fed into the saw part
	if (blob.hasTag("flesh") || (name=="mine"))
	{
		Vec2f pos = this.getPosition();
		Vec2f bpos = blob.getPosition();

		Vec2f off = (bpos - pos);
		f32 len = off.Normalize();

		f32 dot = off * (Vec2f(0, -1).RotateBy(this.getAngleDegrees(), Vec2f()));

		if (dot > 0.8f)
		{
			if (getNet().isClient() && !g_kidssafe) //add blood gfx
			{
				CSprite@ sprite = this.getSprite();
				CSpriteLayer@ chop = sprite.getSpriteLayer("chop");

				if (chop !is null)
				{
					chop.animation.frame = 1;
				}
			}

			return true;
		}
		else
		{
			return false;
		}
	}

	return true;
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (hitBlob !is null)
	{
		Blend(this, hitBlob);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("ignore_saw"))
	{
		return false;
	}
	
	return true;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
    if (blob is null ||
            this.isAttached() || blob.isAttached() ||
            !getSawOn(this))
    {
        return;
    }

    if (canSaw(this, blob))
    {
        Vec2f pos = this.getPosition();
        Vec2f bpos = blob.getPosition();
	blob.server_SetHealth(-1);
        this.server_Hit(blob, bpos, bpos - pos, 0.0f, Hitters::saw);
        this.Tag("sawed");
    }

    if ((blob.getName() == "waterbomb" || blob.getName() == "bomb") && blob.hasTag("activated"))
    {
        Vec2f oldVelocity = blob.getVelocity();
        // bombs very close to the top of the saw have a ratio of 0 and most of the rest has a ratio of 1 
        // using the old bomb position is slightly more reliable when bombs fall from above
        f32 ydiff = Maths::Max(this.getPosition().y - blob.getOldPosition().y + blob.getHeight(), 0.0f);
        f32 ratio = Maths::Clamp01(3.0f * (1.0f - ydiff/this.getHeight()));

        if(isServer())
        {
        	if (blob.getName() == "waterbomb")
        	{
        		// hack; waterbombs have a mass of 200 (which gives them a special interaction with kegs)
        		// but it's annoying here so we're giving it same mass as normal bombs
        		blob.SetMass(20.0); 
        	}

            // give a horizontal boost to the bombs coming from the top based on their original velocity
            f32 xboost = 60.0f * Maths::Clamp(oldVelocity.x / 8.0f, -1.0f, 1.0f) * (1.0f - ratio);

            // bear in mind bombs have custom physics that cap velocity *eventually*
            // this is hacky but gives enough of a nice short boost
            Vec2f newVelocity(
                // mostly random x position, but keep some horizontal momentum when coming from the top
                70.0f * ((float(XORRandom(100)) / 100.0f) - 0.5f) + xboost,
                // small vertical boost to bombs coming from the top, big boost with some randomness for the others
                -(Maths::Max(80.0f + XORRandom(30), 500.0f * ratio - XORRandom(300)))
            );
            
            // make some sparks that go towards the direction the bomb was headed towards
            sparks(blob.getPosition(), 180.0f - oldVelocity.Angle(), 0.5f, 60.0f, 0.5f);
            // make some sparks that go the opposite direction the bomb is going to go *horizontally*
            // this gives the nice feel that sparks were emitted from the collision point
            sparks(blob.getPosition(), newVelocity.Angle(), 2.0f, 20.0f, 3.0f);

            blob.setVelocity(Vec2f_zero);
            blob.AddForce(newVelocity);
            blob.set_Vec2f("bombnado velocity", newVelocity);
            blob.Sync("bombnado velocity", true);

            // shorten the fuse quite significantly by a semi-random amount
            const int fuseTicksLeft = blob.get_s32("bomb_timer") - getGameTime();
            blob.set_s32("bomb_timer", getGameTime() + Maths::Min(fuseTicksLeft / 3 + XORRandom(6), fuseTicksLeft));
            blob.Sync("bomb_timer", true);
        }

        if(isClient())
        {
            Vec2f newVelocity = blob.get_Vec2f("bombnado velocity");

            // play a hit sound with a pitch depending on some parameters for some audio clues
            const f32 typePitchBoost = ((blob.getName() == "waterbomb") ? 0.25f : 0.0f);
            const f32 bottomHitPitchBoost = ratio * 0.06f;
            this.getSprite().PlaySound("ShieldHit", 1.0f, 1.07f + bottomHitPitchBoost + typePitchBoost);

            // make some sparks that go towards the direction the bomb was headed towards
            sparks(blob.getPosition(), 180.0f - oldVelocity.Angle(), 0.5f, 60.0f, 0.5f);
            // make some sparks that go the opposite direction the bomb is going to go *horizontally*
            // this gives the nice feel that sparks were emitted from the collision point
            sparks(blob.getPosition(), newVelocity.Angle(), 2.0f, 20.0f, 3.0f);
        }
    }
}

//only pickable by enemies if they are _under_ this
bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return (byBlob.getTeamNum() == this.getTeamNum() ||
	        byBlob.getPosition().y > this.getPosition().y + 4);
}


//sprite update
void onInit(CSprite@ this)
{
	this.SetZ(-10.0f);

	CSpriteLayer@ chop = this.addSpriteLayer("chop", "/Saw.png", 16, 16);

	if (chop !is null)
	{
		Animation@ anim = chop.addAnimation("default", 0, false);
		anim.AddFrame(3);
		anim.AddFrame(7);
		chop.SetAnimation(anim);
		chop.SetRelativeZ(-1.0f);
	}

	CSpriteLayer@ back = this.addSpriteLayer("back", "/Saw.png", 24, 16);

	if (back !is null)
	{
		Animation@ anim = back.addAnimation("default", 0, false);
		anim.AddFrame(1);
		anim.AddFrame(3);
		back.SetAnimation(anim);
		back.SetRelativeZ(-5.0f);
	}

	this.getBlob().getShape().SetRotationsAllowed(false);
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	this.SetZ(blob.isAttached() ? 10.0f : -10.0f);

	//spin saw blade
	CSpriteLayer@ chop = this.getSpriteLayer("chop");

	if (chop !is null && getSawOn(blob))
	{
		chop.SetFacingLeft(false);

		Vec2f around(0.5f, -0.5f);
		chop.RotateBy(30.0f, around);
	}
}
