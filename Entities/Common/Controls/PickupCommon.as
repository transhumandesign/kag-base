#include "StandardControlsCommon.as"

void GatherPickupBlobs(CBlob@ this)
{
	CBlob@[]@ pickupBlobs;
	this.get("pickup blobs", @pickupBlobs);
	pickupBlobs.clear();
	CBlob@[] blobsInRadius;

	if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() + 50.0f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];

			if (b.canBePickedUp(this))
			{
				pickupBlobs.push_back(b);
			}
		}
	}
}

CBlob@ GetBetterAlternativePickupBlobs(CBlob@[] available_blobs, CBlob@ reference)
{
	if (reference is null)
		return reference;

	CBlob@[] blobsInRadius;
	const string ref_name = reference.getName();
	const u32 ref_quantity = reference.getQuantity();
	Vec2f ref_pos = reference.getPosition();

	CBlob @result = reference;

	for (uint i = 0; i < available_blobs.length; i++)
	{
		CBlob @b = available_blobs[i];
		Vec2f b_pos = b.getPosition();
		if ((b_pos - ref_pos).Length() > 10.0f)
			continue;

		const string name = b.getName();
		const u32 quantity = b.getQuantity();
		if (name == ref_name && quantity > ref_quantity)
			@result = @b;
	}

	return result;
}

void ClearPickupBlobs(CBlob@ this)
{
	this.clear("pickup blobs");
}

void FillAvailable(CBlob@ this, CBlob@[]@ available, CBlob@[]@ pickupBlobs)
{
	for (uint i = 0; i < pickupBlobs.length; i++)
	{
		CBlob @b = pickupBlobs[i];

		if (b !is this && canBlobBePickedUp(this, b))
		{
			available.push_back(b);
		}
	}
}

f32 getPriorityPickupScale(CBlob@ this, CBlob@ b)
{
	u32 gameTime = getGameTime();

	const string thisname = this.getName(),
		name = b.getName();
	u32 unpackTime = b.get_u32("unpack time");

	const bool same_team = b.getTeamNum() == this.getTeamNum();
	const bool material = b.hasTag("material");

	// Military scale factor constants, NOT including military resources
	const float factor_military = 0.4f,
		factor_military_team = 0.6f,
		factor_military_useful = 0.3f,
		factor_military_lit = 0.2f,
		factor_military_important = 0.15f,
		factor_military_critical = 0.1f;

	// Resource scale factor constants
	const float factor_resource_boring = 0.7f,
		factor_resource_useful = 0.5f,
		factor_resource_useful_rare = 0.45f,
		factor_resource_strategic = 0.4f,
		factor_resource_critical = 0.3f;

	// Generic scale factor constants
	const float factor_very_boring = 1.0f,
		factor_common = 0.9f,
		factor_boring = 0.8f,
		factor_important = 0.025f,
		factor_very_important = 0.01f,
		factor_super_important = 0.001f;

	//// MISC ////

	// Special stuff such as flags
	if (b.hasTag("special"))
	{
		return factor_super_important;
	}

	//// MILITARY ////
	{
		// special mine check for unarmed enemy mines
		if (name == "mine" && b.hasTag("mine_priming") && !same_team)
		{
			return factor_important;
		}

		// Military stuff we don't want to pick up when in the same team and always considered lit
		if (name == "mine" || name == "bomb" || name == "waterbomb")
		{
			// Make an exception to the team rule: when the explosive is the holder's
			bool mine = b.getDamageOwnerPlayer() is this.getPlayer();

			return (same_team && !mine) ? factor_military_team : factor_military_lit;
		}

		bool exploding = b.hasTag("exploding");

		// Kegs, really matters when lit (exploding)
		// But we still want a high priority so bombjumping with kegs is easier
		if (name == "keg")
		{
			return exploding ? factor_very_important : factor_military_important;
		}

		// Regular military stuff
		if (name == "boulder" || name == "saw")
		{
			return factor_military;
		}

		if (name == "drill")
		{
			return thisname == "builder" ? factor_military_useful : factor_military;
		}

		if (name == "crate")
		{
			if (same_team)
			{
				return factor_military_team;
			}

			// Consider crates useful usually but unpacking enemy crates important
			return (unpackTime > gameTime && !same_team) ? factor_military_important : factor_military_useful;
		}

		// Other exploding stuff we don't recognize
		if (exploding)
		{
			return factor_military_lit;
		}
	}

	//// MATERIALS ////
	if (material)
	{
		const bool builder = (thisname == "builder");

		if (name == "mat_gold")
		{
			return factor_resource_strategic;
		}

		if (name == "mat_stone")
		{
			return builder ? factor_resource_useful_rare : factor_resource_boring;
		}

		if (name == "mat_wood")
		{
			return builder ? factor_resource_useful : factor_resource_boring;
		}

		const bool knight = (thisname == "knight");

		if (name == "mat_bombs" || name == "mat_waterbombs")
		{
			return knight ? factor_resource_useful : factor_resource_boring;
		}

		const bool archer = (thisname == "archer");

		if (name == "mat_arrows")
		{
			// Lower priority for regular arrows when the archer has more than 15 in the inventory
			return archer && !this.hasBlob("mat_arrows", 15) ? factor_resource_useful : factor_resource_boring;
		}

		if (name == "mat_waterarrows" || name == "mat_firearrows" || name == "mat_bombarrows")
		{
			return archer ? factor_resource_useful_rare : factor_resource_boring;
		}
	}

	//// MISC ////
	if (name == "food" || name == "heart" || (name == "fishy" && b.hasTag("dead"))) // Wait, is there a better way to do that?
	{
		float factor_full_life = (thisname == "archer" ? factor_resource_useful : factor_resource_boring);
		return this.getHealth() < this.getInitialHealth() ? factor_resource_critical : factor_full_life;
	}

	//low priority
	if (name == "log" || b.hasTag("tree"))
	{
		return factor_boring;
	}

	if (name == "bucket" && b.get_u8("filled") > 0)
	{
		return factor_resource_useful;
	}


	// super low priority, dead stuff - sick of picking up corpses
	if (b.hasTag("dead"))
	{
		return factor_very_boring;
	}

	return factor_common;
}

f32 getPriorityPickupScale(CBlob@ this, CBlob@ b, f32 scale)
{
	return scale * getPriorityPickupScale(this, b);
}

CBlob@ getClosestAimedBlob(CBlob@ this, CBlob@[] available)
{
	CBlob@ closest;
	float lowestScore = 16.0f; // TODO provide better sorting routines in the interface

	for (int i = 0; i < available.length; ++i)
	{
		CBlob@ current = available[i];

		float cursorDistance = (this.getAimPos() - current.getPosition()).Length();

		float radius = current.getRadius();
		if (radius > 3.0f && cursorDistance > current.getRadius() * 1.5f)
		{
			continue;
		}

		if (cursorDistance < lowestScore)
		{
			lowestScore = cursorDistance;
			@closest = @current;
		}
	}

	return closest;
}

CBlob@ getClosestBlob(CBlob@ this)
{
	CBlob@ closest;

	CBlob@[]@ pickupBlobs;
	if (this.get("pickup blobs", @pickupBlobs))
	{
		Vec2f pos = this.getPosition();

		CBlob@[] available;
		FillAvailable(this, available, pickupBlobs);

		if (!isTapPickup(this))
		{
			CBlob@ closestAimed = getClosestAimedBlob(this, available);
			if (closestAimed !is null)
			{
				return closestAimed;
			}
		}

		float closestScore = 999999.9f;

		for (uint i = 0; i < available.length; ++i)
		{
			CBlob @b = available[i];
			Vec2f bpos = b.getPosition();

			float maxDist = Maths::Max(this.getRadius() + b.getRadius() + 20.0f, 36.0f);

			float dist = (bpos - pos).getLength();
			float factor = dist / maxDist;
			float score = getPriorityPickupScale(this, b, factor);

			if (score < closestScore)
			{
				closestScore = score;
				@closest = @b;
			}
		}

		if (closest !is null) {
			@closest = @GetBetterAlternativePickupBlobs(available, closest);
		}
	}

	return closest;
}

bool canBlobBePickedUp(CBlob@ this, CBlob@ blob)
{
	float maxDist = Maths::Max(this.getRadius() + blob.getRadius() + 20.0f, 36.0f);

	Vec2f pos = this.getPosition() + Vec2f(0.0f, -this.getRadius() * 0.9f);
	Vec2f pos2 = blob.getPosition();

	Vec2f ray = pos2 - pos;
	bool canRayCast = false;

	CMap@ map = getMap();

	HitInfo@[] hitInfos;
	if(map.getHitInfosFromRay(pos, -ray.getAngle(), ray.Length(), this, hitInfos))
	{
		for (int i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;

			// collide with anything that isn't a platform
			// could do proper platform direction check but probably not needed
			if (b !is null && b !is this && b !is blob && b.isCollidable() && b.getShape().isStatic() && !b.isPlatform())
			{
				canRayCast = false;
				break;

			}

			if(map.isTileSolid(hi.tile))
			{
				canRayCast = false;
				break;
			}

			// if our blob isn't in the list that means the ray stopped at a block
			if (b is blob)
			{
				canRayCast = true;
			}
		}

	} else {
		canRayCast = true;
	}

	return (((pos2 - pos).getLength() <= maxDist)
	        && !blob.isAttached() && !blob.hasTag("no pickup")
	        && (canRayCast || this.isOverlapping(blob)) //overlapping fixes "in platform" issue
	       );
}
