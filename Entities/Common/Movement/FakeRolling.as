const float MAX_ROTATION_SPEED = 60.0f;

void onInit(CBlob@ this)
{
	f32 angle = (this.getNetworkID() * 977) % 360;
	this.set_f32("angle0", angle);
	this.set_f32("angle1", angle);
}

void onTick(CBlob@ this)
{	
	if (this.isAttached())	
	{
		this.set_f32("angle0", 0.0f);
		this.set_f32("angle1", 0.0f);		
		return;
	}
	
	f32 old_angle = this.get_f32("angle" + getGameTime() % 2); 
	Vec2f vel = this.getVelocity();
	
	if (Maths::Abs(vel.x) > 0 && isServer())
	{
		f32 angle = old_angle + Maths::Clamp(vel.x / this.getRadius() * 180.0f / Maths::Pi, -MAX_ROTATION_SPEED, MAX_ROTATION_SPEED);
		if (angle > 360.0f)
			angle -= 360.0f;
		else if (angle < -360.0f)
			angle += 360.0f;
				
		this.set_f32("angle" + (getGameTime() + 1) % 2, angle);
		this.Sync("angle" + (getGameTime() + 1) % 2, true);
	}

	this.setAngleDegrees(old_angle);
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	this.setAngleDegrees(0.0f);
}
