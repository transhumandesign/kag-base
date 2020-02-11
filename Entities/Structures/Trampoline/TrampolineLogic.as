// TrampolineLogic.as

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
	angle = angle > 135 || angle < 45? (holder.isFacingLeft()? 135 : 45) : 90;
	angle -= 90;

	this.setAngleDegrees(-angle);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1, Vec2f point2)
{
	if (blob is null || blob.isAttached() || blob.getShape().isStatic()) return;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ holder = point.getOccupied();

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

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic();
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.hasTag("no pickup");
}
