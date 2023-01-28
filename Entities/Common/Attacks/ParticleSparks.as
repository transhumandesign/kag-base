void sparks(Vec2f at, f32 angle, f32 damage, f32 angleVariation = 180.0f, f32 velocityVariation = 0.0f)
{
	int amount = damage * 5 + XORRandom(5);

	for (int i = 0; i < amount; i++)
	{
		const float randFloat = float(XORRandom(100)) / 100.0f;
		Vec2f vel = getRandomVelocity(angle, damage * 3.0f + velocityVariation * (randFloat - 0.5f), angleVariation);
		vel.y = -Maths::Abs(vel.y) + Maths::Abs(vel.x) / 3.0f - 2.0f - randFloat;
		ParticlePixel(at, vel, SColor(255, 255, 255, 0), true);
	}
}
