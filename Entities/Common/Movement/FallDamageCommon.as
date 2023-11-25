//get the fall damage amount for a given vertical velocity
//returns
//  0 for no damage, no stun
//  <0 for stun only
//  >0 for damage amount

f32 BaseFallSpeed()
{
	const f32 BASE_FALL_VEL = 8.0f;
	return getRules().exists("fall vel modifier") ? getRules().get_f32("fall vel modifier") * BASE_FALL_VEL : BASE_FALL_VEL;
}

f32 FallDamageAmount(float vely)
{
	const f32 base = BaseFallSpeed();
	const f32 ramp = 1.2f;
	bool doknockdown = false;

	if (vely > base)
	{

		if (vely > base * ramp)
		{
			f32 damage = 0.0f;
			doknockdown = true;

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

void CancelFallDamageThisTick(CBlob@ blob)
{
	blob.setVelocity(Vec2f_zero);
	blob.set_u32("falldamage prevent", getGameTime());
}

bool isFallDamageCancelledThisTick(CBlob@ blob)
{
	return blob.exists("falldamage prevent")
		&& (blob.get_u32("falldamage prevent") == getGameTime());
}