#include "Hitters.as";

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!solid || blob is null || blob.hasTag("invincible"))
		return;

	bool hasAttachments = otherTeamHitting(this, blob);
	f32 vel_thresh =  hasAttachments ? 1.0f : 2.0f;
	f32 dir_thresh =  hasAttachments ? -0.7f : 0.25f;

	const f32 vellen = this.getShape().vellen;
	if (blob !is null && vellen > vel_thresh && blob.isCollidable())
	{
		Vec2f pos = this.getPosition();
		Vec2f vel = this.getVelocity();
		Vec2f other_pos = blob.getPosition();
		Vec2f direction = other_pos - pos;
		direction.Normalize();
		vel.Normalize();
		if (vel * direction > dir_thresh)
		{
			f32 power = blob.getShape().isStatic() ? 10.0f * vellen : 2.0f * vellen;
			if (this.getTeamNum() == blob.getTeamNum())
				power = 0.0f;
			this.server_Hit(blob, point1, vel, power, Hitters::flying, false);
		}
	}
}

bool otherTeamHitting(CBlob@ this, CBlob@ blob)
{
	if (this.hasAttached())
	{
		const int otherTeam = blob.getTeamNum();
		int count = this.getAttachmentPointCount();
		for (int i = 0; i < count; i++)
		{
			AttachmentPoint @ap = this.getAttachmentPoint(i);
			if (ap.getOccupied() !is null)
			{
				if (otherTeam != ap.getOccupied().getTeamNum())
				{
					return true;
				}
			}
		}
	}
	return false;
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (hitBlob !is null && customData == Hitters::flying)
	{
		const f32 othermass = hitBlob.getMass();
		if (othermass > 0.0f)
		{
			hitBlob.AddForce(velocity * this.getMass() * 0.1f * othermass / 70.0f);
		}
	}
}
