//tree making logs on death script

#include "TreeCommon.as"

void onDie(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	f32 fall_angle = 0.0f;

	if (this.exists("tree_fall_angle"))
	{
		fall_angle = this.get_f32("tree_fall_angle");
	}

	TreeSegment[]@ segments;
	this.get("TreeSegments", @segments);
	if (segments is null)
		return;

	for (uint i = 0; i < segments.length; i++)
	{
		TreeSegment@ segment = segments[i];
		
		pos = this.getPosition() + (segment.start_pos + segment.end_pos) / 2.0f;
		pos.y -= 4.0f; // TODO: fix logs spawning in ground

		if (getNet().isServer())
		{
			CBlob@ log = server_CreateBlob("log", this.getTeamNum(), pos);
			if (log !is null)
				log.setAngleDegrees(fall_angle);
		}
		
		if (XORRandom(5) == 0)
			return;

		ParticleAnimated("Entities/Effects/Sprites/Leaves", pos + Vec2f(6-XORRandom(12), 0), Vec2f(0,-0.75f), 0.0f, 0.5f, 4, 0.1f, false);
	}

	CSprite@ sprite = this.getSprite();
	int layer_count = sprite.getSpriteLayerCount();

	for (int i = 0; i < layer_count; i++) 
	{
	    ParticlesFromSprite(sprite.getSpriteLayer(i));
	}
	
	// effects
	Sound::Play("Sounds/branches" + (XORRandom(2) + 1) + ".ogg", this.getPosition());
}
