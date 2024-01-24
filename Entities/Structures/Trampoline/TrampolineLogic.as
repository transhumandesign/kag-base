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

	// Fix TDM map trampolines (I'm assuming these have "no pickup")
	if (this.getTeamNum() == 255)
	{
		Animation@ anim = this.getSprite().getAnimation("default");
		anim.AddFrame(5);
		anim.RemoveFrame(0);

		Vec2f[] shape;
		shape.push_back(Vec2f(0, 0));
		shape.push_back(Vec2f(23, 0));
		shape.push_back(Vec2f(23, 7));
		shape.push_back(Vec2f(0, 7));
		// this.getShape().SetShape(shape); // immediately crashes
		this.getShape().AddShape(shape);
	}

	this.Tag("no falldamage");
	this.Tag("medium weight");
	this.Tag("ignore_attach_facing");
	// Because BlobPlacement.as is *AMAZING*
	this.Tag("place norotate");

	this.addCommandID("freeze_angle_at");
	this.addCommandID("unfreeze_tramp");

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	point.SetKeysToTake(key_action1 | key_action2 | key_action3);

	this.getCurrentScript().runFlags |= Script::tick_attached;

	if (this.hasTag("tramp_freeze"))
	{
		ShowMeYourFeet(this, this.get_f32("old_angle"), true);
	}
}

void onTick(CBlob@ this)
{
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
	else if (point.isKeyPressed(key_action2))
	{
		angle = this.get_f32("old_angle");
	}
	else
	{
		angle = getHoldAngle(this, holder, point);
	}

	this.setAngleDegrees(angle);
	this.set_f32("old_angle", angle);
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
		if (velocity_old.Length() < 1.0f) return;

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
			velocity.RotateBy(angle);

			blob.setVelocity(velocity);
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
	if (!attached.isMyPlayer()) return;

	SetHelp(attached, "trampoline help lmb", "", getTranslatedString("$trampoline$ Lock to 45° steps  $KEY_HOLD$$LMB$"), "", 3, true);
	SetHelp(attached, "trampoline help rmb", "", getTranslatedString("$trampoline$ Lock current angle  $KEY_HOLD$$RMB$"), "", 3, true);
	SetHelp(attached, "trampoline help space", "", getTranslatedString("$trampoline$ Add/remove feet  $KEY_TAP$$KEY_SPACE$"), "", 3, true);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (!detached.isMyPlayer()) return;
	RemoveHelps(detached, "trampoline help lmb");
	RemoveHelps(detached, "trampoline help rmb");
	RemoveHelps(detached, "trampoline help space");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isExplosionHitter(customData) && !this.isAttached())
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

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic();
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.hasTag("no pickup");
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
	else if (point.isKeyPressed(key_action2))
	{
		return this.get_f32("old_angle");
	}
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

	f32 height = tilt < 0.9506f ? 7.38241f * Maths::Sin(tilt + 0.49394f) - 2.5f // match bottom vertex
								: 12.0208f * Maths::Sin(tilt - 0.29544f) - 2.5f; // match side vertex

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
		sprite.SetAnimation("default");
		sprite.getSpriteLayer("left_foot").SetVisible(false);
		sprite.getSpriteLayer("right_foot").SetVisible(false);
	}
}
