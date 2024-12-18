const float MAX_ROTATION_SPEED = 60.0f;

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
	if (getNet().isServer() && Maths::Abs(vel.x) > 0.1)
	{
		angle += Maths::Clamp(vel.x / this.getRadius() * 180.0f / Maths::Pi, -MAX_ROTATION_SPEED, MAX_ROTATION_SPEED);
		if (angle > 360.0f)
			angle -= 360.0f;
		else if (angle < -360.0f)
			angle += 360.0f;
		this.set_f32("angle", angle);
		this.setAngleDegrees(angle);
	}
}
