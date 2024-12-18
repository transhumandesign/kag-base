#include "Help.as"
#include "FallDamageCommon.as"

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

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	point.SetKeysToTake(key_action1 | key_action2);

	this.getCurrentScript().runFlags |= Script::tick_attached;
}

void onTick(CBlob@ this)
{
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");

	CBlob@ holder = point.getOccupied();
	if (holder is null) return;

	Vec2f ray = holder.getAimPos() - this.getPosition();
	ray.Normalize();
	
	f32 angle = ray.Angle();

	if (point.isKeyPressed(key_action2))
	{
		// set angle to what was on previous tick
		angle = this.get_f32("old angle");
		this.setAngleDegrees(angle);
	}
	else if (point.isKeyPressed(key_action1))
	{
		// rotate in 45 degree steps
		angle = Maths::Floor((angle - 67.5f) / 45) * 45;
		this.setAngleDegrees(-angle);
	}
	else
	{
		// follow cursor normally
		this.setAngleDegrees(-angle + 90);
	}
	
	this.set_f32("old angle", this.getAngleDegrees());
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1, Vec2f point2)
{
	if (!canBounce(@this, @blob)) return;

	TrampolineCooldown@[]@ cooldowns;
	if (!this.get(Trampoline::TIMER, @cooldowns)) return;

	//shred old cooldown if we have too many
	if (Trampoline::SAFETY && cooldowns.length > Trampoline::COOLDOWN_LIMIT) cooldowns.removeAt(0);

	u16 netid = blob.getNetworkID();
	for(int i = 0; i < cooldowns.length; i++)
	{
		if (cooldowns[i].timer < getGameTime())
		{
			cooldowns.removeAt(i);
			i--;
		}
		else if (netid == cooldowns[i].netid)
		{
			return;
		}
	}

	TrampolineCooldown cooldown(netid, getGameTime() + Trampoline::COOLDOWN);
	cooldowns.push_back(cooldown);

	float angle = this.getAngleDegrees();

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

bool doesCollideWithBlob(CBlob@ trampoline, CBlob@ candidate)
{
	// HACK: tag the candidate with collision immunity before it hits the ground
	if (canBounce(@trampoline, @candidate)) { CancelFallDamageThisTick(@candidate); }

	return candidate.getShape().isStatic();
}

bool canBounce(CBlob@ trampoline, CBlob@ candidate)
{
	if (candidate is null || candidate.isAttached() || candidate.getShape().isStatic()) return false;

	AttachmentPoint@ point = trampoline.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ holder = point.getOccupied();

	//choose whether to jump on team trampolines
	if (candidate.hasTag("player") && candidate.isKeyPressed(key_down) && trampoline.getTeamNum() == candidate.getTeamNum()) return false;

	//cant bounce holder
	if (holder is candidate) return false;

	//cant bounce while held by something attached to something else
	if (holder !is null && holder.isAttached()) return false;

	//prevent knights from flying using trampolines

	//get angle difference between entry angle and the facing angle
	Vec2f pos_delta = (candidate.getPosition() - trampoline.getPosition()).RotateBy(90);
	float delta_angle = Maths::Abs(-pos_delta.Angle() - trampoline.getAngleDegrees());
	if (delta_angle > 180)
	{
		delta_angle = 360 - delta_angle;
	}
	//if more than 90 degrees out, no bounce
	if (delta_angle > 90)
	{
		return false;
	}

	Vec2f velocity_old = candidate.getOldVelocity();
	if (velocity_old.Length() < 1.0f) return false;

	float angle = trampoline.getAngleDegrees();

	Vec2f direction = Vec2f(0.0f, -1.0f);
	direction.RotateBy(angle);

	float velocity_angle = direction.AngleWith(velocity_old);

	if (Maths::Abs(velocity_angle) <= 90) return false;

	return true;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.hasTag("no pickup");
}
