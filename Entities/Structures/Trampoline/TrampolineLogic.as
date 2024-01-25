#include "Help.as";
#include "FallDamageCommon.as";
#include "Hitters.as";

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

class TrampolineCooldown{
	u16 netid;
	u32 timer;
	TrampolineCooldown(u16 netid, u16 timer){this.netid = netid; this.timer = timer;}
};

void onInit(CBlob@ this)
{
	TrampolineCooldown @[] cooldowns;
	this.set(Trampoline::TIMER, cooldowns);
	this.getShape().getConsts().collideWhenAttached = true;

	this.Tag("setup_feet_tick");
	// this.getCurrentScript().runFlags |= Script::tick_attached;

	this.Tag("no falldamage");
	this.Tag("medium weight");
	this.Tag("ignore_attach_facing");
	// Because BlobPlacement.as is *AMAZING*
	this.Tag("place norotate");

	this.addCommandID("freeze_angle_at");
	this.addCommandID("unfreeze_tramp");

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	point.SetKeysToTake(key_action1 | key_action3);

	if (this.hasTag("tramp_freeze"))
	{
		ShowMeYourFeet(this, this.get_f32("old_angle"), true);
	}
}

void onTick(CBlob@ this)
{
	// Map trampoline setup tick
	if (this.hasTag("setup_feet_tick"))
	{
		this.Untag("setup_feet_tick");
		if (this.exists("map_alpha"))
		{
			// from BasePNGLoader.as - getAngleFromChannel()
			switch (this.get_u8("map_alpha") & 0x30)
			{
				// case  0: {this.set_f32("old_angle",   0.0f); ShowMeYourFeet(this,   0.0f); break;}
				case 16: {this.set_f32("old_angle",  90.0f); ShowMeYourFeet(this,  90.0f); break;}
				// case 32: {this.set_f32("old_angle", 180.0f); ShowMeYourFeet(this, 180.0f); break;}
				case 48: {this.set_f32("old_angle", 270.0f); ShowMeYourFeet(this, 270.0f); break;}
			}
		}
		else if (this.getTeamNum() == 255)
		{
			ShowMeYourFeet(this, 0.0f);
		}

		this.getCurrentScript().runFlags |= Script::tick_attached;
	}

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");

	CBlob@ holder = point.getOccupied();
	if (holder is null) return;

	if (holder.isMyPlayer() && point.isKeyJustPressed(key_action3))
	{
		if (this.hasTag("feet_active"))
		{
			if (!this.hasTag("tramp_freeze"))
			{
				return; // already sent command
			}

			this.Untag("tramp_freeze");
			Sound::Play("bone_fall.ogg", this.getPosition());

			this.SendCommand(this.getCommandID("unfreeze_tramp"));
		}
		else
		{
			if (this.hasTag("tramp_freeze"))
			{
				return; // already sent command
			}

			this.Tag("tramp_freeze");
			// this.getShape().SetRotationsAllowed(false);
			Sound::Play("hit_wood.ogg", this.getPosition());

			CBitStream params;
			f32 angle = (point.isKeyPressed(key_action2)) 
							? this.get_f32("old_angle")
							: getHoldAngle(this, holder, point);
			params.write_f32(angle);
			this.SendCommand(this.getCommandID("freeze_angle_at"), params);
		}
	}

	f32 angle;
	if (this.hasTag("tramp_freeze") || this.hasTag("feet_active"))
	{
		angle = this.get_f32("old_angle");
	}
	// else if (point.isKeyPressed(key_action2))
	// {
	// 	angle = this.get_f32("old_angle");
	// }
	else
	{
		angle = getHoldAngle(this, holder, point);
	}

	this.setAngleDegrees(angle);
	// this.set_f32("old_angle", angle);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1, Vec2f point2)
{
	if (blob is null || blob.isAttached() || blob.getShape().isStatic()) return;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ holder = point.getOccupied();

	//choose whether to pass through team trampolines
	if (blob.hasTag("player") 
		&& (blob.isKeyPressed(key_down)
			|| (this.getAngleDegrees() > 120		// Hold W to pass downward-facing trampolines
				&& this.getAngleDegrees() < 240
				&& blob.isKeyPressed(key_up)))
		&& this.getTeamNum() == blob.getTeamNum())
	{
		return;
	}

	//cant bounce holder
	if (holder is blob) return;

	//cant bounce while held by something attached to something else
	if (holder !is null && holder.isAttached()) return;

	//prevent knights from flying using trampolines

	// Blob needs to be coming towards bouncy side (4 pixels above center pos)
	Vec2f offset = blob.getOldPosition() - this.getPosition();
	offset.RotateBy(-this.getAngleDegrees());
	if (offset.y > -4) return;

	TrampolineCooldown@[]@ cooldowns;
	if (!this.get(Trampoline::TIMER, @cooldowns)) return;

	//shred old cooldown if we have too many
	if (Trampoline::SAFETY && cooldowns.length > Trampoline::COOLDOWN_LIMIT) cooldowns.removeAt(0);

	u16 netid = blob.getNetworkID();
	bool block = false;
	for(int i = 0; i < cooldowns.length; i++)
	{
		if (cooldowns[i].timer < getGameTime())
		{
			cooldowns.removeAt(i);
			i--;
		}
		else if (netid == cooldowns[i].netid)
		{
			block = true;
			break;
		}
	}
	if (!block)
	{
		Vec2f velocity_old = blob.getOldVelocity();
		if (velocity_old.Length() + this.getVelocity().Length() < 1.0f) return;

		float angle = this.getAngleDegrees();

		Vec2f direction = Vec2f(0.0f, -1.0f);
		direction.RotateBy(angle);

		// // Unnecessary after earlier offset check
		// float velocity_angle = direction.AngleWith(velocity_old);
		// if (Maths::Abs(velocity_angle) > 90)
		{
			TrampolineCooldown cooldown(netid, getGameTime() + Trampoline::COOLDOWN);
			cooldowns.push_back(cooldown);

			Vec2f velocity = Vec2f(0, -Trampoline::SCALAR);

			if (Trampoline::PHYSICS)
			{
				Vec2f new_vel = velocity;

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
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("freeze_angle_at"))
	{
		f32 angle;
		if (!params.saferead_f32(angle)) return;

		this.set_f32("old_angle", angle);
		this.setAngleDegrees(angle);
		ShowMeYourFeet(this, angle);
	}
	else if (cmd == this.getCommandID("unfreeze_tramp"))
	{
		RemoveFeet(this);
	}
}

// for help text
void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (this.getTeamNum() == 255)
	{
		RemoveFeet(this);
		this.Untag("invincible");
	}
	if (!attached.isMyPlayer()) return;

	SetHelp(attached, "trampoline help lmb", "", getTranslatedString("$trampoline$ Lock to 45° steps  $KEY_HOLD$$LMB$"), "", 3, true);
	// SetHelp(attached, "trampoline help rmb", "", getTranslatedString("$trampoline$ Lock current angle  $KEY_HOLD$$RMB$"), "", 3, true);
	SetHelp(attached, "trampoline help space", "", getTranslatedString("$trampoline$ Add/remove feet  $KEY_TAP$$KEY_SPACE$"), "", 3, true);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (!detached.isMyPlayer()) return;
	RemoveHelps(detached, "trampoline help lmb");
	// RemoveHelps(detached, "trampoline help rmb");
	RemoveHelps(detached, "trampoline help space");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isExplosionHitter(customData) && !this.isAttached() && this.getTeamNum() != 255)
	{
		RemoveFeet(this);

		if (isClient())
		{
			makeGibParticle("TrampFeet.png", this.getPosition(),
							this.getVelocity() + getRandomVelocity(90, 3, 80) + Vec2f(0.0f, -2.0f),
							0, 0, Vec2f(8, 8), 2.0f, 20, "material_drop.ogg");
			makeGibParticle("TrampFeet.png", this.getPosition(),
							this.getVelocity() + getRandomVelocity(90, 3, 80) + Vec2f(0.0f, -2.0f),
							0, 1, Vec2f(8, 8), 2.0f, 20, "material_drop.ogg");
		}
	}
	return damage;
}

void onHealthChange(CBlob@ this, f32 health_old)
{
	if (!isClient()) return;

	if (this.getHealth() <= this.getInitialHealth() / 2)
	{
		CSprite@ sprite = this.getSprite();

		Animation@ anim = sprite.getAnimation("default");
		anim.AddFrame(2);
		anim.RemoveFrame(0);

		@anim = sprite.getAnimation("bounce");
		anim.RemoveFrame(6);
		anim.AddFrame(2);

		@anim = sprite.getAnimation("pack");
		const int[] frames = {2, 3, 0, 1};
		anim.AddFrames(frames);
		for (int i = 0; i < 4; ++i)
		{
			anim.RemoveFrame(0);
		}

		@anim = sprite.getAnimation("unpack");
		anim.RemoveFrame(3);
		anim.AddFrame(2);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic();
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	if (this.hasTag("no pickup"))
	{
		return false;
	}
	else if (byBlob.getTeamNum() == this.getTeamNum())
	{
		return true;
	}
	else
	{
		// Can only be picked up from non-bouncy side
		Vec2f offset = byBlob.getPosition() - this.getPosition();
		offset.RotateBy(-this.getAngleDegrees());
		return (offset.y > 4);
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

f32 getHoldAngle(CBlob@ this, CBlob@ holder, AttachmentPoint@ point)
{
	if (point.isKeyPressed(key_action1))
	{
		f32 angle;
		angle = (holder.getAimPos() - this.getPosition()).Angle();
		angle = -Maths::Floor((angle - 67.5f) / 45) * 45;
		return angle;
	}
	// else if (point.isKeyPressed(key_action2))
	// {
	// 	return this.get_f32("old_angle");
	// }
	else
	{
		return (-1.0f * (holder.getAimPos() - this.getPosition()).Angle() + 90 + 360) % 360;
	}
}

void onInit(CSprite@ this)
{
	CSpriteLayer@ left = this.addSpriteLayer("left_foot", "TrampFeet.png", 8, 8);
	if (left !is null)
	{
		left.addAnimation("default", 0, false);
		left.animation.AddFrame(0);

		left.SetRelativeZ(-1);
		left.SetVisible(false);
		left.SetIgnoreParentFacing(true);
	}

	CSpriteLayer@ right = this.addSpriteLayer("right_foot", "TrampFeet.png", 8, 8);
	if (right !is null)
	{
		right.addAnimation("default", 0, false);
		right.animation.AddFrame(1);

		right.SetRelativeZ(-1);
		right.SetVisible(false);
		right.SetIgnoreParentFacing(true);
	}

	CBlob@ blob = this.getBlob();
	if (blob.hasTag("tramp_freeze"))
	{
		ShowMeYourFeet(blob, blob.get_f32("old_angle"), false, true);
	}
}

void ShowMeYourFeet(CBlob@ this, f32 tramp_angle, bool skip_sprite=false, bool skip_shape=false)
{
	tramp_angle = (tramp_angle + 360) % 360;
	f32 tilt = tramp_angle;
	if (tilt > 180)
		tilt = 360 - tilt;

	tilt *= 0.0174533f; // radians

	f32 height = tilt < 0.9506f ? 7.38241f * Maths::Sin(tilt + 0.49394f) - 3.5f // match bottom vertex
								: 12.0208f * Maths::Sin(tilt - 0.29544f) - 3.5f; // match side vertex

	Vec2f left_offset = Vec2f(0, height);
	Vec2f right_offset = Vec2f(0, height);

	f32 halfwidth = 8 * Maths::Abs(Maths::Cos(tilt));

	bool lame_legs = false;
	if (tramp_angle < 100) // normal
	{
		left_offset.x = -halfwidth;
		right_offset.x = halfwidth;
	}
	else if (tramp_angle < 155) // right spotlight
	{
		left_offset.x = -halfwidth - 1;
		right_offset.x = -halfwidth + 3;
	}
	else if (tramp_angle < 205) // upside down
	{
		left_offset = Vec2f(-8, 0);
		right_offset = Vec2f(8, 0);
		lame_legs = true;
	}
	else if (tramp_angle < 260) // left spotlight
	{
		right_offset.x = halfwidth + 1;
		left_offset.x = halfwidth - 3;
	}
	else // normal
	{
		left_offset.x = -halfwidth;
		right_offset.x = halfwidth;
	}

	if (!skip_shape)
	{
		this.Tag("feet_active");
		this.Tag("tramp_freeze");
		Vec2f centerofmass = (left_offset + right_offset) / 2;
		centerofmass.RotateBy(-tramp_angle);
		this.getShape().SetCenterOfMassOffset(centerofmass);
		// this.getShape().SetRotationsAllowed(false);
	}

	if (!lame_legs && !skip_shape)
	{
		Vec2f[] legShape;
		Vec2f offset;
		Vec2f center;

		// Left foot
		legShape.clear();
		offset = left_offset;
		offset.RotateBy(-tramp_angle);
		center = Vec2f(11.5f, 3.5f) + offset;
		// legShape.push_back(center + Vec2f(-3.5f, -3.5f));
		legShape.push_back(center + Vec2f(3.5f, -3.5f));
		legShape.push_back(center + Vec2f(3.5f, 3.5f));
		legShape.push_back(center + Vec2f(-3.5f, 3.5f));
		for (int i = 0; i < legShape.size(); ++i)
		{
			legShape[i].RotateBy(-tramp_angle, center);
		}
		this.getShape().AddShape(legShape);

		// Right foot
		legShape.clear();
		offset = right_offset;
		offset.RotateBy(-tramp_angle);
		center = Vec2f(11.5f, 3.5f) + offset;
		legShape.push_back(center + Vec2f(-3.5f, -3.5f));
		// legShape.push_back(center + Vec2f(3.5f, -3.5f));
		legShape.push_back(center + Vec2f(3.5f, 3.5f));
		legShape.push_back(center + Vec2f(-3.5f, 3.5f));
		for (int i = 0; i < legShape.size(); ++i)
		{
			legShape[i].RotateBy(-tramp_angle, center);
		}
		this.getShape().AddShape(legShape);
	}

	if (!isClient() || skip_sprite) return;

	CSprite@ sprite = this.getSprite();

	CSpriteLayer@ left = sprite.getSpriteLayer("left_foot");
	left.ResetTransform();
	left.TranslateBy(left_offset);
	left.SetVisible(true);

	CSpriteLayer@ right = sprite.getSpriteLayer("right_foot");
	right.ResetTransform();
	right.TranslateBy(right_offset);
	right.SetVisible(true);

	if (lame_legs) return; // don't rotate

	// cancel angle so the offset is normal
	if (tilt > 180)
	{
		left.RotateBy(-tramp_angle, Vec2f_zero);
		right.RotateBy(-tramp_angle, Vec2f_zero);
	}
	else
	{
		left.RotateBy(-tramp_angle, Vec2f_zero);
		right.RotateBy(-tramp_angle, Vec2f_zero);
	}
}

void RemoveFeet(CBlob@ this)
{
	this.Untag("tramp_freeze");
	this.Untag("feet_active");
	// this.getShape().SetRotationsAllowed(true);
	this.getShape().SetCenterOfMassOffset(Vec2f_zero);
	this.getShape().RemoveShape(1);
	this.getShape().RemoveShape(1);

	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		sprite.getSpriteLayer("left_foot").SetVisible(false);
		sprite.getSpriteLayer("right_foot").SetVisible(false);
	}
}
