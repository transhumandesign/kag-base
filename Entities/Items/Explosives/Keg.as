// Keg logic
#include "Hitters.as";
#include "ActivationThrowCommon.as"
#include "ParticlesCommon.as"
#include "FireParticle.as"

void onInit(CBlob@ this)
{
	this.Tag("bomberman_style");
	this.set_f32("map_bomberman_width", 24.0f);
	this.set_f32("explosive_radius", 64.0f);
	this.set_f32("explosive_damage", 10.0f);
	this.set_u8("custom_hitter", Hitters::keg);
	this.set_string("custom_explosion_sound", "Entities/Items/Explosives/KegExplosion.ogg");
	this.set_f32("map_damage_radius", 72.0f);
	this.set_f32("map_damage_ratio", 0.8f);
	this.set_bool("map_damage_raycast", true);
	this.set_f32("keg_time", 180.0f);  // 180.0f
	this.Tag("medium weight");
	this.Tag("slash_while_in_hand"); // allows knights to knock kegs off enemies' backs

	this.set_u16("_keg_carrier_id", 0xffff);

	CSprite@ sprite = this.getSprite();

	CSpriteLayer@ fuse = this.getSprite().addSpriteLayer("fuse", "Keg.png" , 16, 16, 0, 0);

	if (fuse !is null)
	{
		fuse.addAnimation("default", 0, false);
		int[] frames = {8, 9, 10, 11, 12, 13};
		fuse.animation.AddFrames(frames);
		fuse.SetOffset(Vec2f(3, -4));
		fuse.SetRelativeZ(1);
	}

	this.set_f32("important-pickup", 30.0f);
}

//sprite update

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	this.animation.frame = (this.animation.getFramesCount()) * (1.0f - (blob.getHealth() / blob.getInitialHealth()));

	s32 timer = blob.get_s32("explosion_timer") - getGameTime();

	if (timer < 0)
	{
		return;
	}

	CSpriteLayer@ fuse = this.getSpriteLayer("fuse");

	if (fuse is null)
		return;

	fuse.animation.frame = 1 + (fuse.animation.getFramesCount() - 1) * (1.0f - ((timer + 5) / f32(blob.get_f32("keg_time"))));

	if (fuse.animation.frame == 0 || getGameTime() % 3 != 0)
		return;

	CParticle@ p = MakeEmberParticle(this, fuse);
#ifdef STAGING
	if (p !is null) {
		MakeBasicLightParticle(p.position, p.velocity, this.getBlob().getLightColor(), 0.95, 0.3, 60);
	}
#endif
}

void onTick(CBlob@ this)
{
	if (this.isInFlames() && !this.hasTag("exploding") && isServer())
	{
		server_Activate(this);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	s32 timer = this.get_s32("explosion_timer") - getGameTime();
	if (timer > 60 || timer < 0 || this.getDamageOwnerPlayer() is null) // don't change keg ownership for final 2 seconds of fuse
	{
		this.SetDamageOwnerPlayer(attached.getPlayer());
	}
	
	if (isServer())
	{
		this.set_u16("_keg_carrier_id", attached.getNetworkID());
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (getNet().isServer() &&
	        !isExplosionHitter(customData) &&
	        (hitterBlob is null || hitterBlob.getTeamNum() != this.getTeamNum()))
	{
		u16 id = this.get_u16("_keg_carrier_id");
		if (id != 0xffff)
		{
			CBlob@ carrier = getBlobByNetworkID(id);
			if (carrier !is null)
			{
				this.server_DetachFrom(carrier);
			}
		}
	}

	switch (customData)
	{
		case Hitters::sword:
		case Hitters::arrow:
			damage *= 0.25f; //quarter damage from these
			break;
		case Hitters::water:
			if (hitterBlob.getName() == "bucket" && this.hasTag("exploding") && isServer())
			{
				server_Deactivate(this);
			}
			break;
		case Hitters::keg:
			if (isServer())
			{
				if (!this.hasTag("exploding"))
				{
					server_Activate(this);
				}

				//set fuse to shortest fuse time - either current time or new random time
				//so it doesn't explode at the exact same time as hitter keg
				this.set_s32("explosion_timer", Maths::Min(this.get_s32("explosion_timer"), getGameTime() + XORRandom(this.get_f32("keg_time")) / 3));
				this.Sync("explosion_timer", true);
			}
			damage *= 0.0f; //invincible to allow keg chain reaction
			break;
		default:
			damage *= 0.5f; //half damage from everything else
	}

	return damage;
}

const Vec2f[] FuseOffsets = {
	Vec2f(4.0, 2.0),
	Vec2f(1.0, 4.5),
	Vec2f(0.0, 3.5),
	Vec2f(-2.5, 3.5),
	Vec2f(-3.5, 1.0),
};

const float[] FuseRotations = {
	45.0,
	135.0,
	135.0,
	135.0,
	225.0,
};

Vec2f getFuseWorldPos(CSprite@ &in this, CSpriteLayer@ &in fuse, float angle)
{
	Vec2f realPos = this.getBlob().getPosition();

	Vec2f offset = FuseOffsets[fuse.animation.frame - 1];
	if (this.isFacingLeft())
		offset.x *= -1.0f;

	Vec2f pos = fuse.getWorldTranslation() - offset;
	pos.RotateByDegrees(angle, realPos);

	return pos;
}

CParticle@ MakeEmberParticle(CSprite@ &in this, CSpriteLayer@ &in fuse)
{
	Random r(XORRandom(1000));

	float angle = this.getBlob().getShape().getAngleDegrees();
	Vec2f pos = getFuseWorldPos(this, fuse, angle);

	CParticle@ p = makeFireParticle(pos);

	if (p is null)
		return null;

	p.gravity = Vec2f(0.0, 0.01 + r.NextFloat() * 0.025);
	p.lighting = true;
	p.fastcollision = true;
	p.Z = r.NextRanged(4) == 0 ? 100 : -100 ;

	float rot = FuseRotations[fuse.animation.frame - 1];
	Vec2f vel = Vec2f(this.isFacingLeft() ? -1.0 : 1.0, 1.0);
	vel *= r.NextFloat() * 0.5f;

	vel.RotateByDegrees((this.isFacingLeft() ? -rot : rot) + angle);

	p.velocity = vel;
	
	return @p;
}