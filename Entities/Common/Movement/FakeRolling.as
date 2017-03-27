void onInit(CBlob@ this)
{
	f32 angle = (this.getNetworkID() * 977) % 360;
	this.set_f32("angle", angle);

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_moving;
	this.getCurrentScript().runFlags |= Script::tick_not_sleeping;
}

void onTick(CBlob@ this)
{
	Vec2f vel = this.getVelocity();
	if (getNet().isServer() && Maths::Abs(vel.x) > 0.1)
	{
		f32 angle = this.get_f32("angle");
		angle += vel.x * this.getRadius();
		if (angle > 360.0f)
			angle -= 360.0f;
		else if (angle < -360.0f)
			angle += 360.0f;
		this.set_f32("angle", angle);
		this.setAngleDegrees(angle);
	}
}
