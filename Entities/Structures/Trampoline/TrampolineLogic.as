#include "Help.as";
#include "Hitters.as";

namespace Trampoline
{
	const string TIMER = "trampoline_timer";
	const u16 COOLDOWN = 7;
	const u8 SCALAR = 10;
	const bool SAFETY = true;
	const int COOLDOWN_LIMIT = 8;
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

	this.Tag("no falldamage");
	this.Tag("medium weight");
	// Because BlobPlacement.as is *AMAZING*
	this.Tag("place norotate");

	this.addCommandID("freeze_angle_at");

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	point.SetKeysToTake(key_action1 | key_action2 | key_action3);

	this.getCurrentScript().runFlags |= Script::tick_attached;
}

void onTick(CBlob@ this)
{
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");

	CBlob@ holder = point.getOccupied();
	if (holder is null) return;

	f32 angle;
	if (this.hasTag("tramp_freeze"))
	{
		if (point.isKeyJustPressed(key_action3)) // unfreeze
		{
			this.set_f32("old angle", angle);
			this.Untag("tramp_freeze");
			this.getShape().SetRotationsAllowed(true);
			if (holder.isMyPlayer())
			{
				Sound::Play("bone_fall.ogg", this.getPosition());
			}
			if (isClient())
			{
				// do not show me your feet
				CSprite@ sprite = this.getSprite();
				sprite.SetAnimation("default");
				sprite.getSpriteLayer("left_foot").SetVisible(false);
				sprite.getSpriteLayer("right_foot").SetVisible(false);
			}
		}

		return;
	}
	else if (point.isKeyPressed(key_action2))
	{
		// set angle to what was on previous tick
		angle = this.get_f32("old angle");
	}
	else if (point.isKeyPressed(key_action1))
	{
		// rotate in 45 degree steps
		angle = (holder.getAimPos() - this.getPosition()).Angle();
		angle = -Maths::Floor((angle - 67.5f) / 45) * 45;
	}
	else
	{
		// follow cursor normally
		angle = getHoldAngle(this, holder);
	}

	this.setAngleDegrees(angle);
	this.set_f32("old angle", angle);

	if (point.isKeyJustPressed(key_action3)) // wasn't already frozen, so freeze
	{
		this.Tag("tramp_freeze");
		this.getShape().SetRotationsAllowed(false);
		if (holder.isMyPlayer())
		{
			Sound::Play("hit_wood.ogg", this.getPosition());
			CBitStream params;
			params.write_f32(angle);
			this.SendCommand(this.getCommandID("freeze_angle_at"), params);
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1, Vec2f point2)
{
	if (blob is null || blob.isAttached() || blob.getShape().isStatic()) return;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ holder = point.getOccupied();

	//choose whether to jump on team trampolines
	if (blob.hasTag("player") && blob.isKeyPressed(key_down) && this.getTeamNum() == blob.getTeamNum()) return;

	//cant bounce holder
	if (holder is blob) return;

	//cant bounce while held by something attached to something else
	if (holder !is null && holder.isAttached()) return;

	//prevent knights from flying using trampolines

	//get angle difference between entry angle and the facing angle
	Vec2f pos_delta = (blob.getPosition() - this.getPosition()).RotateBy(90);
	float delta_angle = Maths::Abs(-pos_delta.Angle() - this.getAngleDegrees());
	if (delta_angle > 180)
	{
		delta_angle = 360 - delta_angle;
	}
	//if more than 90 degrees out, no bounce
	if (delta_angle > 90)
	{
		return;
	}

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
		if (velocity_old.Length() < 1.0f) return;

		float angle = this.getAngleDegrees();

		Vec2f direction = Vec2f(0.0f, -1.0f);
		direction.RotateBy(angle);

		float velocity_angle = direction.AngleWith(velocity_old);

		if (Maths::Abs(velocity_angle) > 90)
		{
			TrampolineCooldown cooldown(netid, getGameTime() + Trampoline::COOLDOWN);
			cooldowns.push_back(cooldown);

			Vec2f velocity = Vec2f(0, -Trampoline::SCALAR);
			velocity.RotateBy(angle);

			blob.setVelocity(velocity);

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

		this.setAngleDegrees(angle);

		if (isClient())
		{
			ShowMeYourFeet(this.getSprite(), angle);
		}
	}
}

// for help text
void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (!attached.isMyPlayer()) return;

	SetHelp(attached, "trampoline help lmb", "", getTranslatedString("$trampoline$ Lock to 45° steps  $KEY_HOLD$$LMB$"), "", 3, true);
	SetHelp(attached, "trampoline help rmb", "", getTranslatedString("$trampoline$ Lock current angle  $KEY_HOLD$$RMB$"), "", 3, true);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (!detached.isMyPlayer()) return;
	RemoveHelps(detached, "trampoline help lmb");
	RemoveHelps(detached, "trampoline help rmb");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isExplosionHitter(customData) && !this.isAttached())
	{
		this.Untag("tramp_freeze");
		this.getShape().SetRotationsAllowed(true);
		if (isClient())
		{
			makeGibParticle("TrampFeet.png", this.getPosition(),
							this.getVelocity() + getRandomVelocity(90, 3, 80) + Vec2f(0.0f, -2.0f),
							0, 0, Vec2f(8, 8), 2.0f, 20, "material_drop.ogg");
			makeGibParticle("TrampFeet.png", this.getPosition(),
							this.getVelocity() + getRandomVelocity(90, 3, 80) + Vec2f(0.0f, -2.0f),
							0, 1, Vec2f(8, 8), 2.0f, 20, "material_drop.ogg");

			CSprite@ sprite = this.getSprite();
			sprite.SetAnimation("default");
			sprite.getSpriteLayer("left_foot").SetVisible(false);
			sprite.getSpriteLayer("right_foot").SetVisible(false);
		}
	}
	return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic();
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.hasTag("no pickup");
}

f32 getHoldAngle(CBlob@ this, CBlob@ holder)
{
	return (-1.0f * (holder.getAimPos() - this.getPosition()).Angle() + 90 + 360) % 360;
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
}

void ShowMeYourFeet(CSprite@ sprite, f32 tramp_angle)
{
	f32 tilt = tramp_angle;
	if (tilt > 180)
		tilt = 360 - tilt;

	tilt *= 0.0174533f; // radians

	f32 height = tilt < 0.9506f ? 7.38241f * Maths::Sin(tilt + 0.49394f) - 2.5f // match bottom vertex
								: 12.0208f * Maths::Sin(tilt - 0.29544f) - 2.5f; // match side vertex

	Vec2f left_offset = Vec2f(0, height);
	Vec2f right_offset = Vec2f(0, height);

	f32 halfwidth = 8 * Maths::Abs(Maths::Cos(tilt));

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
		// i give up
		// nah this is juust too weird
		sprite.SetAnimation("legs");
		return;
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

	CSpriteLayer@ left = sprite.getSpriteLayer("left_foot");
	left.ResetTransform();
	left.TranslateBy(left_offset);
	left.SetVisible(true);

	CSpriteLayer@ right = sprite.getSpriteLayer("right_foot");
	right.ResetTransform();
	right.TranslateBy(right_offset);
	right.SetVisible(true);

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
