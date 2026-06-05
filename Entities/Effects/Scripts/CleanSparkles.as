// sparkle particles if blob has tag "sparkling"

#define CLIENT_ONLY

const u8 sparkleTime = 68;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickIfTag = "sparkling";
 
	if (!this.exists("sparkling time"))
		this.set_u16(("sparkling time"), getGameTime());
}

void onTick(CBlob@ this)
{
	if (v_fastrender || this.hasTag("bloody"))
	{
		return;
	}

	if (XORRandom(7) == 0)
	{
		if (this.get_u16("sparkling time") + sparkleTime < getGameTime())
			this.Untag("sparkling");

		Vec2f position = this.getPosition();
		f32 width = this.getWidth();
		f32 height = this.getHeight();
		Vec2f sparkle_position = Vec2f(position.x + XORRandom(width + 1) - width/2, position.y + XORRandom(height + 1) - height/2);
	
		// sparkle particle
		CParticle@ p = ParticleAnimated(
		"SparkleParticle.png", 		// file name
		sparkle_position, 			// position
		Vec2f_zero, 				// velocity
		0,				 			// rotation
		1.0f, 						// scale
		3,							// ticks per frame
		0.0f,						// gravity
		true);						// self lit

		if (p !is null)
		{
			p.Z = 1000.0f;
		}
	}
}
