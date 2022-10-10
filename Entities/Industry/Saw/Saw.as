// Saw logic

#include "Hitters.as"
#include "GenericButtonCommon.as"

const string toggle_id = "toggle_power";
const string sawteammate_id = "sawteammate";

void onInit(CBlob@ this)
{
	this.Tag("saw");
	this.set_u32("bomb_time", 0);
	this.set_u8("bombs_exploded", 0);

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
		SetSawOn(this, !getSawOn(this));
		UpdateFrame(this);
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

	tobeblended.Tag("sawed");

	// on saw player or dead body - disable the saw
	if (
		(tobeblended.getPlayer() !is null || //player
		tobeblended.hasTag("flesh")) && //dead body
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

	string n = blob.getName();

	if (
	    n == "migrant" ||
	    n == "wooden_door" ||
	    n == "mat_wood" ||
	    n == "tree_bushy" ||
	    n == "tree_pine" ||
	    (n == "mine" && blob.getTeamNum() == this.getTeamNum()))
	{
		return false;
	}

	//flesh blobs or enemy mine has to be fed into the saw part
	if (blob.hasTag("flesh") || (n == "mine"))
	{
		Vec2f pos = this.getPosition();
		Vec2f bpos = blob.getPosition();

		Vec2f off = (bpos - pos);
		f32 len = off.Normalize();

		f32 dot = off * (Vec2f(0, -1).RotateBy(this.getAngleDegrees(), Vec2f()));

		if (dot > 0.8f)
		{
			if (isClient() && blob.hasTag("flesh") && !g_kidssafe) //add blood gfx
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

//we have contact!
void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || !getNet().isServer() ||
	        this.isAttached() || blob.isAttached() ||
	        !getSawOn(this))
	{
		return;
	}

	if (canSaw(this, blob))
	{
		Vec2f pos = this.getPosition();
		Vec2f bpos = blob.getPosition();
		this.Tag("sawed");
		this.server_Hit(blob, bpos, bpos - pos, 0.0f, Hitters::saw);

		if (blob.getName() == "bomb")
		{
			if (this.get_u8("bombs_exploded") == 0)
			{
				this.set_u32("bomb_time", getGameTime());
			}

			this.add_u8("bombs_exploded", 1);
		}
	}
}

void onTick(CBlob@ this)
{
	if (this.get_u32("bomb_time") == 0) return;

	if (getGameTime() - this.get_u32("bomb_time") > 8)
	{
		this.set_u32("bomb_time", 0);

		if (this.get_u8("bombs_exploded") >= 3)
		{
			this.server_Hit(this, this.getPosition(), this.getPosition(), 100.0f, Hitters::crush);
		}

		this.set_u8("bombs_exploded", 0);
	}
}

void UpdateFrame(CBlob@ this)
{
	bool set = getSawOn(this);

	if (isClient()) //closed/opened gfx
	{
		CSprite@ s = this.getSprite();

		u8 frame = set ? 0 : 1;

		s.animation.frame = frame;

		CSpriteLayer@ back = s.getSpriteLayer("back");
		if (back !is null)
		{
			back.animation.frame = frame;
		}

		CSpriteLayer@ chop = s.getSpriteLayer("chop");
		if (chop !is null)
		{
			chop.SetOffset(Vec2f());
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
	bool active = getSawOn(blob);

	if (chop !is null && active)
	{
		chop.SetFacingLeft(false);

		Vec2f around(0.5f, -0.5f);
		chop.RotateBy(30.0f, around);
	}
	
	// fixes wrong sprite on disabled saw on joining online server
	if (this.animation.frame == 0 && !active)
	{
		UpdateFrame(blob);
	}
}
