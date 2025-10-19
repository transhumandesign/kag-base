// satchel logic

#include "Hitters.as";
#include "TeamStructureNear.as";
#include "ActivationThrowCommon.as"

//config

s32 satchel_fuse = 120;

//setup

void onInit(CBlob@ this)
{
	this.getShape().getVars().waterDragScale = 24.0f;
	this.getCurrentScript().tickIfTag = "exploding";

	this.Tag("activatable");

	Activate@ func = @onActivate;
	this.set("activate handle", @func);
}

//start ugly satchel logic :)

void onTick(CBlob@ this)
{
	if (this.hasTag("exploding"))
	{
		//stick to map
		if (this.isOnMap())
		{
			this.setAngleDegrees(90 - this.getGroundNormal().Angle());
			this.getShape().SetStatic(true);
		}
		else if (this.isAttached()) //pulled off
		{
			this.getShape().SetStatic(false);
		}

		this.SetLight(true);
		this.SetLightRadius(32);

		if (!this.exists("satchel_timer")) //just got set
		{
			this.getSprite().SetEmitSound("/Sparkle.ogg");
			this.getSprite().SetEmitSoundPaused(false);
			this.set_s32("satchel_timer", getGameTime() + satchel_fuse);
			this.Sync("satchel_timer", true);
			this.Sync("exploding", true);
		}

		s32 timer = this.get_s32("satchel_timer") - getGameTime();

		if (timer <= 0)
		{
			if (getNet().isServer())
			{
				Combust(this);
			}
		}
		else
		{
			SColor lightColor = SColor(255, 255, Maths::Min(255, timer + 50), 0);
			this.SetLightColor(lightColor);

			if (XORRandom(2) == 0)
			{
				sparks(this.getPosition() + Vec2f(XORRandom(8) - 4.0f, XORRandom(4) - 2.0f), this.getAngleDegrees(), 1.5f + (XORRandom(10) / 5.0f), lightColor);
			}
		}
	}
}

void Combust(CBlob@ this)
{
	this.server_SetHealth(-10.0f);
	this.Tag("exploding");
	this.server_Die();
}

//if splashed with water,
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::water)
	{
		this.Tag("wet");
	}
	else if (customData == Hitters::fire)
	{
		this.Tag("exploding");
	}

	return damage;
}

//sprite

void onInit(CSprite@ this)
{
	this.getCurrentScript().tickIfTag = "exploding";
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	//if (blob.hasTag("exploding"))
	//if (!blob.isInWater())
	{
		this.SetAnimation("flaming");
		s32 timer = blob.get_s32("satchel_timer") - getGameTime();

		if (timer < 0)
		{
			return;
		}

		if (timer > 60)
		{
			this.animation.frame = 0;
		}
		else
		{
			this.animation.frame = 1;
		}
	}
}

void sparks(Vec2f at, f32 angle, f32 speed, SColor color)
{
	Vec2f vel = getRandomVelocity(angle + 90.0f, speed, 45.0f);
	at.y -= 3.0f;
	ParticlePixel(at, vel, color, true, 119);
}


void onDie(CBlob@ this)
{
	this.getSprite().SetEmitSoundPaused(true);
	ParticlesFromSprite(this.getSprite());

	if (this.hasTag("exploding"))
	{
		//fire flash particle
		ParticleAnimated("Entities/Effects/Sprites/FireFlash.png",
		                 this.getPosition() + Vec2f(0, -4), Vec2f(0, 0.5f), 0.0f, 1.0f,
		                 2,
		                 0.0f, true);
		Sound::Play("Entities/Common/Sounds/FireRoar.ogg", this.getPosition());

		if (getNet().isServer())
		{
			CMap@ map = getMap();
			Vec2f pos = this.getPosition();
			// hit all in radius with burn hitter, needed for some things to catch alight!
			HitInfo@[] hitInfos;

			if (map.getHitInfosFromArc(pos, 0, 360, 32, this, @hitInfos))
			{
				for (uint i = 0; i < hitInfos.length; i++)
				{
					HitInfo@ hi = hitInfos[i];

					if (hi.blob !is null) // blob
					{
						if (hi.blob.getTeamNum() == this.getTeamNum())   // no TK
						{
							continue;
						}

						this.server_Hit(hi.blob, hi.hitpos, hi.blob.getPosition() - pos, 0.5f, Hitters::fire);
					}
				}
			}

			if (!isTeamStructureNear(this))
			{
				map.server_setFireWorldspace(pos, true);
				map.server_setFireWorldspace(pos + Vec2f(0, 8), true);
				map.server_setFireWorldspace(pos + Vec2f(0, -8), true);
				map.server_setFireWorldspace(pos + Vec2f(8, 0), true);
				map.server_setFireWorldspace(pos + Vec2f(-8, 0), true);

				map.server_setFireWorldspace(pos + Vec2f(8, 8), true);
				map.server_setFireWorldspace(pos + Vec2f(8, -8), true);
				map.server_setFireWorldspace(pos + Vec2f(8, 8), true);
				map.server_setFireWorldspace(pos + Vec2f(-8, -8), true);
			}
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (!solid)
	{
		return;
	}

	f32 vellen = this.getOldVelocity().Length();

	if (vellen > 1.7f)
	{
		Sound::Play("/material_drop", this.getPosition(), Maths::Min(vellen / 8.0f, 1.1f));
	}
}


// run the tick so we explode in inventory
void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.doTickScripts = true;
}

// custom callback
void onActivate(CBitStream@ params)
{
	if (!isServer()) return;

	u16 this_id;
	if (!params.saferead_u16(this_id)) return;

	CBlob@ this = getBlobByNetworkID(this_id);
	if (this is null) return;

	this.Tag("exploding");
	this.Tag("activated");

	this.Sync("exploding", true);
	this.Sync("activated", true);
}