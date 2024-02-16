#include "FallDamageCommon.as";

namespace Trampoline
{
	const string TIMER = "trampoline_timer";
	const u16 COOLDOWN = 7;
	const f32 SCALAR = 10;
	const f32 SOFT_SCALAR = 8; // Cap for bouncing without holding W
	const f32 UP_BOOST = 1.5f;
	const u8 BOOST_RANGE = 60;
	const bool SAFETY = true;
	const int COOLDOWN_LIMIT = 8;

	const bool PHYSICS = true; // adjust angle to account for blob's previous velocity
	const float PERPENDICULAR_BOUNCE = 1.0f; // strength of angle adjustment
}

void Bounce(CBlob@ this, CBlob@ blob, Vec2f point1 = Vec2f_zero)
{
	f32 angle = this.getAngleDegrees();
	Vec2f velocity = Vec2f(0, -Trampoline::SCALAR);

	if (Trampoline::PHYSICS)
	{
		Vec2f new_vel = velocity;
		Vec2f velocity_old = blob.getOldVelocity();

		velocity_old.RotateBy(-angle);
		new_vel.x = velocity_old.x * Trampoline::PERPENDICULAR_BOUNCE;
		new_vel *= Trampoline::SCALAR / new_vel.getLength();
		// velocity_old.RotateBy(angle); // change velocity_old back?

		new_vel.RotateBy(angle);
		velocity.RotateBy(angle);

		// If a player is holding the opposite direction of the angle adjustment, use normal velocity
		if (blob.hasTag("player") && velocity.y < 0)
		{
			bool escaped = (new_vel.y - velocity.y >= 2 && blob.isKeyPressed(key_up))
			            || (new_vel.x > velocity.x && blob.isKeyPressed(key_left))
			            || (new_vel.x < velocity.x && blob.isKeyPressed(key_right));
			if (!escaped)
			{
				velocity = new_vel;
			}	
		}
		else
		{
			velocity = new_vel;
		}
	}
	else
	{
		velocity.RotateBy(angle);
	}

	if (blob.hasTag("player"))
	{
		if (blob.isKeyPressed(key_up))
		{
			velocity *= scaleWithUpBoost(velocity);
		}
		else
		{
			if (velocity.y < -Trampoline::SOFT_SCALAR)
			{
				velocity.y = -Trampoline::SOFT_SCALAR;
			}
		}
	}
	else
	{
		velocity *= scaleWithUpBoost(velocity);
	}

	if (blob.hasTag("player") && Maths::Abs(velocity.x) > 5) // moveVars.stoppingFastCap
	{
		blob.Tag("stop_air_fast");
		blob.Untag("dont stop til ground");
	}
	blob.setVelocity(velocity);
	ProtectFromFall(blob);
	if (blob.getName() == "arrow")
	{
		blob.setPosition(point1);
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetAnimation("default");
		sprite.SetAnimation("bounce");
		sprite.PlaySound("TrampolineJump.ogg");
	}
}

f32 scaleWithUpBoost(Vec2f vel)
{
	f32 boost = 0.0f;
	if (Trampoline::UP_BOOST != 0)
	{
		// boost factor
		boost = (Trampoline::BOOST_RANGE - Maths::Abs(180 - ((vel.getAngleDegrees() + 90) % 360))) // range - degrees from up
		        / (1.0f * Trampoline::BOOST_RANGE);                                                // / max boost range
		if (boost > 0)
		{
			boost *= Trampoline::UP_BOOST;
		}
		else
		{
			boost = 0.0f;
		}
	}

	return (Trampoline::SCALAR + boost) / vel.getLength();
}
