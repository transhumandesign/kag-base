//fall damage for all characters and fall damaged items
// apply Rules "fall vel modifier" property to change the damage velocity base

#include "Hitters.as";
#include "KnockedCommon.as";
#include "FallDamageCommon.as";

const u8 knockdown_time = 12;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickIfTag = "dead";
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!solid 
		|| this.isInInventory()
		|| this.hasTag("invincible")
		|| (this.exists("last fall hit") && this.get_u32("last fall hit") == getGameTime()))
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
		bool doknockdown = true;

		// better check for trampolines
		CBlob@[] blobs_around;
		if (getMap().getBlobsInRadius(this.getPosition(), this.getRadius() * 4, blobs_around))
		{
			for (uint i = 0; i < blobs_around.length; i++)
			{
				CBlob@ b = blobs_around[i];

				if (!b.hasTag("no falldamage")) continue;

				Vec2f b_pos = b.getPosition();
				Vec2f pos = this.getPosition();

				if (Maths::Abs(b_pos.x - pos.x) > b.getWidth()) continue;

				if (Maths::Abs(b_pos.y - pos.y) > b.getWidth()) continue;

				return;
			}
		}

		if (damage > 0.0f)
		{
			if (damage > 0.1f)
			{
				this.server_Hit(this, point1, normal, damage, Hitters::fall);
				this.set_u32("last fall hit", getGameTime()); // fixes bug of this code running twice in the same tick
			}
			else
			{
				doknockdown = false;
			}
			
			
		}

		if (doknockdown)
			setKnocked(this, knockdown_time);

		if (!this.hasTag("should be silent"))
		{
			if (this.getHealth() > damage) //not dead
				Sound::Play("/BreakBone", this.getPosition());
			else
			{
				Sound::Play("/FallDeath.ogg", this.getPosition());
			}
		}
	}
}

void onTick(CBlob@ this)
{
	this.Tag("should be silent");
	this.getCurrentScript().tickFrequency = 0;
}
