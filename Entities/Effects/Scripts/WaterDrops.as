// drop water particles if blob has tag "wet"

#define CLIENT_ONLY

#include "FireCommon.as";

void onInit(CSprite@ this)
{
	this.getCurrentScript().tickIfTag = "wet";
}

void onTick(CSprite@ this)
{
	if (v_fastrender)
	{
		return;
	}

	CBlob@ blob = this.getBlob();

	if (blob is null || blob.hasTag(burning_tag))
	{
		return;
	}

	if (!blob.isInWater() && XORRandom(10) == 0)
	{
		Vec2f position = blob.getPosition();
		f32 width = blob.getWidth();
		f32 height = blob.getHeight();
		Vec2f waterdrop_position = Vec2f(position.x + XORRandom(width + 1) - width/2, position.y + XORRandom(height + 1) - height/2);
		Vec2f velo = blob.getVelocity();
	
		// water drop particle
		CParticle@ p = ParticleAnimated(
		"WaterDrop.png", 			// file name
		waterdrop_position, 		// position
		velo, 						// velocity
		velo.getAngle(), 			// rotation
		1.0f, 						// scale
		2,							// ticks per frame
		0.12f,						// gravity
		false);						// self lit

		// water drip sound
		p.AddDieFunction("WaterDrops.as", "DripSound");
	}
}

void DripSound(CParticle@ p)
{
	if (getMap().isTileSolid(p.position))
	{
		Sound::Play("water_dripping" + XORRandom(5), p.position);
	}
}
