const float MAX_ROTATION_SPEED = 60.0f;

void onInit(CBlob@ this)
{
	f32 angle = (this.getNetworkID() * 977) % 360;
	this.set_f32("angle 0", angle);
	this.set_f32("angle 1", angle);
	this.set_bool("should rotate 0", true);
	this.set_bool("should rotate 1", true);
}

void onTick(CBlob@ this)
{	
	if (this.isAttached())	
	{
		this.set_f32("angle 0", 0.0f);
		this.set_f32("angle 1", 0.0f);		
		return;
	}
	
	f32 old_angle 			= this.get_f32("angle " + getGameTime() % 2); 
	bool old_should_rotate 	= this.get_bool("should rotate " + getGameTime() % 2);
	
	if (isServer())
	{
		Vec2f vel 				= this.getVelocity();
		bool new_should_rotate	= false;
	
		if (Maths::Abs(vel.x) > 0)
		{
			f32 angle = old_angle + Maths::Clamp(vel.x / this.getRadius() * 180.0f / Maths::Pi, -MAX_ROTATION_SPEED, MAX_ROTATION_SPEED);
			if (angle > 360.0f)
				angle -= 360.0f;
			else if (angle < -360.0f)
				angle += 360.0f;
					
			this.set_f32("angle " + (getGameTime() + 1) % 2, angle);
			this.Sync("angle " + (getGameTime() + 1) % 2, true);
			
			new_should_rotate = true;
		}

		this.set_bool("should rotate " + (getGameTime() + 1) % 2, new_should_rotate);
		this.Sync("should rotate " + (getGameTime() + 1) % 2, true);
	}

	if (old_should_rotate)
	{
		this.setAngleDegrees(old_angle);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	this.setAngleDegrees(0.0f);
}
