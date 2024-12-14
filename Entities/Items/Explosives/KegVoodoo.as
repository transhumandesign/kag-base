#include "ActivationThrowCommon.as"

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(true);
	this.getShape().getVars().waterDragScale = 8.0f;
	this.getShape().getConsts().collideWhenAttached = true;

	this.set_f32("explosive_radius", 96.0f);
	this.set_f32("explosive_damage", 10.0f);
	this.set_string("custom_explosion_sound", "Entities/Items/Explosives/KegExplosion.ogg");
	this.set_f32("map_damage_radius", 64.0f);
	this.set_f32("map_damage_ratio", 0.4f);
	this.set_bool("map_damage_raycast", true);
	this.set_f32("keg_time", 300.0f);
	this.set_bool("explosive_teamkill", true);

	this.Tag("activatable");

	Activate@ activation_handle = @onActivate;
	this.set("activate handle", @activation_handle);

	Activate@ deactivation_handle = @onDeactivate;
	this.set("deactivate handle", @deactivation_handle);

	this.addCommandID("activate client");
	this.addCommandID("deactivate client");

	this.getCurrentScript().tickFrequency = 10;
	this.getCurrentScript().tickIfTag = "exploding";
}

void onTick(CBlob@ this)
{
	// HACK, TODO: add a script for stuff like this or something
	if (!this.hasTag("activated") && isServer()) //admin frozen?
	{
		server_Deactivate(this);
	}
	else
	{
		s32 timer = this.get_s32("explosion_timer") - getGameTime();

		if (timer <= 0)
		{
			if (getNet().isServer())
			{
				Boom(this);
			}
		}
		else
		{
			SColor lightColor = SColor(255, 255, Maths::Min(255, uint(timer * 0.7)), 0);
			this.SetLightColor(lightColor);			

			if (timer < 90)
			{
				f32 speed = 1.0f + (90.0f - f32(timer)) / 90.0f;
				this.getSprite().SetEmitSoundSpeed(speed);
				this.getSprite().SetEmitSoundVolume(speed);
			}
		}
	}
}

/* custom callback
Kegs can be activated by:
Arrow.as - fire arrow hit
ActivateHeldObject.as - "activate/throw" command ActivateBlob (called in KnightLogic.as)
Keg.as - onHit by keg
Keg.as - onTick, in flames
There is no instance of kegs being activated with a direct client->server command */
void onActivate(CBitStream@ params)
{
	if (!isServer()) return;

	u16 this_id;
	if (!params.saferead_u16(this_id)) return;

	CBlob@ this = getBlobByNetworkID(this_id);
	if (this is null) return;

	this.Tag("activated");
	this.set_s32("explosion_timer", getGameTime() + this.get_f32("keg_time"));
	this.Tag("exploding");

	this.Sync("activated", true);
	this.Sync("explosion_timer", true);
	this.Sync("exploding", true);

	// not sure if necessary for server
	this.SetLight(true);
	this.SetLightRadius(this.get_f32("explosive_radius") * 0.5f);

	this.SendCommand(this.getCommandID("activate client"));
}

/* custom callback
Kegs can be deactivated by:
Keg.as - onHit by bucket
KegVoodoo.as - onTick for freeze-by-admin check
There is no instance of kegs being activated with a direct client->server command */
void onDeactivate(CBitStream@ params)
{
	if (!isServer()) return;

	u16 this_id;
	if (!params.saferead_u16(this_id)) return;

	CBlob@ this = getBlobByNetworkID(this_id);
	if (this is null) return;

	this.Untag("activated");
	this.set_s32("explosion_timer", 0);
	this.Untag("exploding");

	this.Sync("activated", true);
	this.Sync("explosion_timer", true);
	this.Sync("exploding", true);

	// not sure if necessary for server
	this.SetLight(false);

	this.SendCommand(this.getCommandID("deactivate client"));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate client") && isClient())
	{
		this.SetLight(true);
		this.SetLightRadius(this.get_f32("explosive_radius") * 0.5f);
		this.getSprite().SetEmitSound("/Sparkle.ogg");
		this.getSprite().SetEmitSoundSpeed(1.0f);
		this.getSprite().SetEmitSoundVolume(1.0f);
		this.getSprite().SetEmitSoundPaused(false);
	}
	else if (cmd == this.getCommandID("deactivate client") && isClient())
	{
		this.SetLight(false);
		this.getSprite().SetEmitSoundPaused(true);

		CSpriteLayer@ fuse = this.getSprite().getSpriteLayer("fuse");
		if (fuse !is null)
		{
			fuse.animation.frame = 0;
		}
	}
}

void Boom(CBlob@ this)
{
	this.server_SetHealth(-1.0f);
	this.server_Die();

	if (isClient()) 
	{
		// screenshake when close to a Keg

		CBlob @blob = getLocalPlayerBlob();
		CPlayer@ player = getLocalPlayer();
		Vec2f pos;

	    CCamera @camera = getCamera();
		if (camera !is null) 
		{
			// If the player is a spectating, base their location off of their camera.	
			if (player !is null && player.getTeamNum() == getRules().getSpectatorTeamNum())
			{
				pos = camera.getPosition();
			}
			else if (blob !is null)
			{
				pos = blob.getPosition();
			} 
			else 
			{
				return;
			}

			pos -= this.getPosition();
			f32 dist = pos.Length();
			if (dist < 300) 
			{
				ShakeScreen(200, 60, this.getPosition());
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	Vec2f dir = velocity;
	dir.Normalize();
	this.AddForce(dir * 30);
	return damage;
}

void onDie(CBlob@ this)
{
	this.getSprite().SetEmitSoundPaused(true);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (!solid || this.isAttached())
	{
		return;
	}

	f32 vellen = this.getOldVelocity().Length();

	if (vellen > 1.7f)
	{
		Sound::Play("/WoodLightBump", this.getPosition(), Maths::Min(vellen / 8.0f, 1.1f));

		//printf("vellen " + vellen );
		if (this.hasTag("exploding") && vellen > 8.0f)
		{
			Boom(this);
		}
	}
}

void sparks(Vec2f at, f32 angle, f32 speed, SColor color)
{
	Vec2f vel = getRandomVelocity(angle + 90.0f, speed, 45.0f);
	at.y -= 3.0f;
	ParticlePixel(at, vel, color, true, 119);
}

// run the tick so we explode in inventory
void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (this.hasTag("exploding"))
	{
		this.doTickScripts = true;
	}
}
