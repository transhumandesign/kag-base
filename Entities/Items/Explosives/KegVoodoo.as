//#include "ThrowCommon.as";

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(true);
	this.getShape().getVars().waterDragScale = 8.0f;
	this.getShape().getConsts().collideWhenAttached = true;
	this.addCommandID("deactivate");

	this.set_f32("explosive_radius", 96.0f);
	this.set_f32("explosive_damage", 10.0f);
	this.set_string("custom_explosion_sound", "Entities/Items/Explosives/KegExplosion.ogg");
	this.set_f32("map_damage_radius", 64.0f);
	this.set_f32("map_damage_ratio", 0.4f);
	this.set_bool("map_damage_raycast", true);
	this.set_f32("keg_time", 300.0f);
	this.set_bool("explosive_teamkill", true);

	this.getCurrentScript().tickFrequency = 10;
	this.getCurrentScript().tickIfTag = "exploding";
}

void onTick(CBlob@ this)
{
	if (!this.hasTag("activated")) //admin frozen?
	{
		this.SendCommand(this.getCommandID("deactivate"));
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

			if (XORRandom(2) == 0)
			{
				sparks(this.getPosition(), this.getAngleDegrees(), 1.5f + (XORRandom(10) / 5.0f), lightColor);
			}

			if (timer < 90)
			{
				f32 speed = 1.0f + (90.0f - f32(timer)) / 90.0f;
				this.getSprite().SetEmitSoundSpeed(speed);
				this.getSprite().SetEmitSoundVolume(speed);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();

	if (cmd == this.getCommandID("activate"))
	{
		this.Tag("activated");
		this.set_s32("explosion_timer", getGameTime() + this.get_f32("keg_time"));
		this.Tag("exploding");
		this.SetLight(true);
		this.SetLightRadius(this.get_f32("explosive_radius") * 0.5f);
		this.getSprite().SetEmitSound("/Sparkle.ogg");
		this.getSprite().SetEmitSoundPaused(false);
	}
	else if (cmd == this.getCommandID("deactivate"))
	{
		this.Untag("activated");
		this.set_s32("explosion_timer", 0);
		this.Untag("exploding");
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
