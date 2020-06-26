
const int ABSORB_COUNT = 100;
const string ABSORBED_PROP = "absorbed";


void spongeUpdateSprite(CSprite@ this, u8 absorbed)
{
	uint16 old_frame_index = this.getFrameIndex();
	this.animation.setFrameFromRatio(f32(absorbed) / ABSORB_COUNT);
	if (old_frame_index > this.getFrameIndex())
	{
		makeSteamPuff(this.getBlob());
	}
}


void makeSteamParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	const f32 rad = this.getRadius();
	Vec2f random = Vec2f(XORRandom(128) - 64, XORRandom(128) - 64) * 0.015625f * rad;
	ParticleAnimated(filename, this.getPosition() + random, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}

void makeSteamPuff(CBlob@ this)
{
	const f32 velocity = 1.0f;
	const int smallparticles = 5;
	makeSteamParticle(this, Vec2f(), "MediumSteam");
	for (int i = 0; i < smallparticles; i++)
	{
		f32 randomness = (XORRandom(32) + 32) * 0.015625f * 0.5f + 0.75f;
		Vec2f vel = getRandomVelocity(-90, velocity * randomness, 360.0f);
		makeSteamParticle(this, vel);
	}
}
