//cheaper analogy to FakeRolling.as
// - use when you just need the sprite to turn and there's only one sprite layer

void onInit(CBlob@ this)
{
	f32 angle = (this.getNetworkID() * 977) % 360;
	this.set_f32("angle", angle);
	this.set_f32("old_angle", angle);

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_moving;
	this.getCurrentScript().runFlags |= Script::tick_not_sleeping;
}

void onTick(CBlob@ this)
{
	f32 angle = this.get_f32("angle");
	this.set_f32("old_angle", angle);

	Vec2f vel = this.getVelocity();
	if (Maths::Abs(vel.x) > 0.1)
	{
		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			angle += vel.x * this.getRadius();
			if (angle > 360.0f)
				angle -= 360.0f;
			else if (angle < -360.0f)
				angle += 360.0f;
			this.set_f32("angle", angle);

			sprite.ResetTransform();
			sprite.RotateBy(angle, Vec2f());
		}
	}
}
