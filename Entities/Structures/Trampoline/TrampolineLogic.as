// TrampolineLogic.as

namespace Trampoline
{
	// const string TIMER = "trampoline_timer";
	// const u16 COOLDOWN = 7;
	const u8 SCALAR = 10;
}

void onInit(CBlob@ this)
{
	// this.set_u32(Trampoline::TIMER, 0);

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

	CBlob@ holder = this.getAttachments().getAttachedBlob("PICKUP", 0);
	if(holder is null) return;

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
	if(holder is blob) return;

	//cant bounce while held by something attached to something else
	if (holder !is null && holder.isAttached()) return;

	// if (this.get_u32(Trampoline::TIMER) < getGameTime())
	// {
	Vec2f velocity_old = blob.getOldVelocity();
	if (velocity_old.Length() < 1.0f) return;

	float angle = this.getAngleDegrees();

	Vec2f direction = Vec2f(0.0f, -1.0f);
	direction.RotateBy(angle);

	float velocity_angle = direction.AngleWith(velocity_old);

	if (Maths::Abs(velocity_angle) > 90)
	{
		// this.set_u32(Trampoline::TIMER, getGameTime() + Trampoline::COOLDOWN);

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
	// }
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic();
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.hasTag("no pickup");
}
