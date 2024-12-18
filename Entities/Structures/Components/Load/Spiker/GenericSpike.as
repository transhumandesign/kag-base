// GenericSpike.as

#include "Hitters.as";

namespace Spike
{
	enum pointing
	{
		pointing_up = 0,
		pointing_right,
		pointing_down,
		pointing_left
	};

	enum state
	{
		hidden = 0,
		stabbing,
		falling
	};
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (!isServer() || this.get_u8("state") == Spike::hidden || blob is null || !blob.hasTag("flesh") || blob.hasTag("invincible")) return;

	Vec2f velocity = blob.getOldVelocity();
	velocity.Normalize();

	const u16 angle_point = this.getAngleDegrees() / 90;
	const u16 angle_collision = velocity.Angle();

	bool pierced = false;

	switch (angle_point)
	{
		case Spike::pointing_up:
			pierced = angle_collision <= 315 && angle_collision >= 225;
			break;

		case Spike::pointing_right:
			pierced = angle_collision <= 225 && angle_collision >= 135;
			break;

		case Spike::pointing_down:
			pierced = angle_collision <= 135 && angle_collision >= 45;
			break;

		case Spike::pointing_left:
			pierced = angle_collision <= 45 || angle_collision >= 315;
			break;
	}

	if (!pierced) return;

	this.server_Hit(blob, blob.getPosition(), blob.getVelocity() * -1.0f, 0.5f, Hitters::spikes, true);
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (!this.hasTag("bloody"))
	{
		this.Tag("bloody");
		CSprite@ sprite = this.getSprite();
		sprite.SetAnimation("blood");
		sprite.animation.SetFrameIndex(this.get_u8("state"));
	}
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	CSprite@ sprite = this.getSprite();
	if (this.hasTag("bloody"))
	{
		sprite.SetAnimation("blood");
	}
	sprite.animation.SetFrameIndex(this.get_u8("state"));

	return true;
}
