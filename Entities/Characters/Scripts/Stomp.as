
#include "/Entities/Common/Attacks/Hitters.as";
#include "KnockedCommon.as"

const u8 STOMP_AGAIN_THRESHOLD = 15;

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null)   // map collision?
	{
		return;
	}

	if (!solid)
	{
		return;
	}

	//dead bodies dont stomp
	if (this.hasTag("dead"))
	{
		return;
	}

	// server only
	if (!getNet().isServer() || !blob.hasTag("player")) { return; }

	if (this.getPosition().y < blob.getPosition().y - 2)
	{
		float enemydam = 0.0f;
		f32 vely = this.getOldVelocity().y;

		if (vely > 10.0f)
		{
			enemydam = 2.0f;
		}
		else if (vely > 5.5f)
		{
			enemydam = 1.0f;
		}

		if (enemydam > 0)
		{
			this.server_Hit(blob, this.getPosition(), Vec2f(0, 1) , enemydam, Hitters::stomp);

			blob.set_u16("stomped_time", getGameTime());
			blob.set_u16("stomped_by_id", this.getNetworkID());
			blob.Sync("stomped_time", true);
			blob.Sync("stomped_by_id", true);
		}
	}
}

// effects

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::stomp && damage > 0.0f && velocity.y > 0.0f && worldPoint.y < this.getPosition().y)
	{
		this.getSprite().PlaySound("Entities/Characters/Sounds/Stomp.ogg");
		setKnocked(this, 15, true);
	}

	return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (!this.exists("stomped_time"))
	{
		return true;
	}

	u16 stomped_time = this.get_u16("stomped_time");
	CBlob@ stomper = getBlobByNetworkID(this.get_u16("stomped_by_id"));
	bool recently_stomped_by_blob = (stomper !is null && stomper is blob && stomped_time + STOMP_AGAIN_THRESHOLD > getGameTime());
	bool falling_faster_than_blob = this.getVelocity().y > blob.getVelocity().y;

	return !(recently_stomped_by_blob && falling_faster_than_blob);
}
