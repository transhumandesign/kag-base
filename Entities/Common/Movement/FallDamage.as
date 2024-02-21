//fall damage for all characters and fall damaged items
// apply Rules "fall vel modifier" property to change the damage velocity base

#include "Hitters.as";
#include "KnockedCommon.as";
#include "FallDamageCommon.as";

const u8 knockdown_time = 12;

void onInit(CBlob@ this)
{
	// Init saveable from fall damage
	this.getCurrentScript().tickIfTag = "will_go_oof";
	this.set_u32("safe_from_fall", 0); // Tick granted temp fall immunity
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!solid || this.isInInventory() || this.hasTag("invincible"))
	{
		return;
	}

	if (blob !is null && (blob.hasTag("player") || blob.hasTag("no falldamage")))
	{
		return; //no falldamage when stomping
	}

	f32 vely = this.getOldVelocity().y;

	if (vely < 0 || Maths::Abs(normal.x) > Maths::Abs(normal.y) * 2) { return; }

	f32 damage = FallDamageAmount(vely);
	if (damage != 0.0f) //interesting value
	{
		if (isSavedFromFall(this)) return;

		if (shouldFallDamageWait(point1, this))
		{
			this.set_u32("tick_to_oof", getGameTime() + 2);
			this.set_f32("oof_damage", damage);
			this.Tag("will_go_oof");
		}
		else
		{
			Oof(this, damage);
		}
	}
}

void onTick(CBlob@ this)
{
	if (!this.exists("tick_to_oof"))
	{
		this.Untag("will_go_oof");
		return;
	}

	if (getGameTime() >= this.get_u32("tick_to_oof"))
	{
		this.Untag("will_go_oof");
		Oof(this, this.get_f32("oof_damage"));
	}

}

void Oof(CBlob@ this, f32 damage)
{
	if (!this.hasTag("dead"))
	{				
		if (this.getHealth() > damage) //not dead
			Sound::Play("/BreakBone", this.getPosition());
		else
		{
			Sound::Play("/FallDeath.ogg", this.getPosition());
		}
	}

	if (damage > 0.1f)
	{
		this.server_Hit(this, this.getPosition(), Vec2f(0.0f, -1.0f), damage, Hitters::fall);
	}

	setKnocked(this, knockdown_time);
}
