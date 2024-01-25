

// Fall damage protection (ex. trampolines can prevent fall damage)
//
// 1. Give blobs that can be protected a u32("safe_from_fall
// 2. When detecting a fall collision:
//		a. Cancel the effect if the blob already isSavedFromFall()
//		b. Check shouldFallDamageWait()
//		c. If it should wait, tag with "will_go_oof" and store any fall info needed in props
//			i. Ex. set a "tick_to_oof" a couple ticks forward to know when to apply the fall
//		d. Otherwise just apply the fall effect
// 3. The blob needs a script with tickIfTag="will_go_oof" to handle delayed falls

bool isSavableFromFall(CBlob@ blob)
{
	// have to init this u32 for blobs to be saveable
	return (blob.exists("safe_from_fall"));
}

bool isSavedFromFall(CBlob@ blob)
{
	return (blob.exists("safe_from_fall")
			&& getGameTime() - blob.get_u32("safe_from_fall") <= 1);
}

bool shouldFallDamageWait(Vec2f groundpos, CBlob@ blob)
{
	if (!isSavableFromFall(blob)) return false;
	
	CBlob@[] groundblobs;
	if (getMap().getBlobsInRadius(groundpos, blob.getRadius(), @groundblobs))
	{
		for (int i = 0; i < groundblobs.length; ++i)
		{
			CBlob@ b = groundblobs[i];

			if (b !is null && b.hasTag("no falldamage"))
			{
				return true;
			}
		}
	}
	return false;
}

void ProtectFromFall(CBlob@ blob)
{
	if (!isSavableFromFall(blob)) return;

	// have to use this tag to indicate fall damage was delayed
	if (blob.hasTag("will_go_oof"))
	{
		blob.Untag("will_go_oof");
	}
	blob.set_u32("safe_from_fall", getGameTime());
}


// ------------------------------------------------------------------


f32 BaseFallSpeed()
{
	const f32 BASE_FALL_VEL = 8.0f;
	return getRules().exists("fall vel modifier") ? getRules().get_f32("fall vel modifier") * BASE_FALL_VEL : BASE_FALL_VEL;
}

//get the fall damage amount for a given vertical velocity
//returns
//  0 for no damage, no stun
//  <0 for stun only
//  >0 for damage amount
f32 FallDamageAmount(float vely)
{
	const f32 base = BaseFallSpeed();
	const f32 ramp = 1.2f;

	if (vely > base)
	{

		if (vely > base * ramp)
		{
			f32 damage = 0.0f;

			if (vely < base * Maths::Pow(ramp, 1))
			{
				damage = 0.5f;
			}
			else if (vely < base * Maths::Pow(ramp, 2))
			{
				damage = 1.0f;
			}
			else if (vely < base * Maths::Pow(ramp, 3))
			{
				damage = 2.0f;
			}
			else if (vely < base * Maths::Pow(ramp, 4)) //regular dead
			{
				damage = 8.0f;
			}
			else //very dead
			{
				damage = 100.0f;
			}

			damage *= 0.5f;

			return damage;
		}

		return -1.0f;
	}
	return 0.0f;
}
