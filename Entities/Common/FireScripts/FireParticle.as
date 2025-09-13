//spawning a generic fire particle

CParticle@ makeFireParticle(Vec2f pos, int smokeRandom = 1)
{
	string texture;

	switch (XORRandom(XORRandom(smokeRandom) == 0 ? 4 : 2))
	{
		case 0: texture = "Entities/Effects/Sprites/SmallFire1.png"; break;

		case 1: texture = "Entities/Effects/Sprites/SmallFire2.png"; break;

		case 2: texture = "Entities/Effects/Sprites/SmallSmoke1.png"; break;

		case 3: texture = "Entities/Effects/Sprites/SmallSmoke2.png"; break;
	}

	return ParticleAnimated(texture, pos, Vec2f(0, 0), 0.0f, 1.0f, 5, -0.1, true);
}


CParticle@ makeSmokeParticle(Vec2f pos, f32 gravity = -0.06f)
{
	string texture;

	switch (XORRandom(2))
	{
		case 0: texture = "Entities/Effects/Sprites/SmallSmoke1.png"; break;

		case 1: texture = "Entities/Effects/Sprites/SmallSmoke2.png"; break;
	}

	return ParticleAnimated(texture, pos, Vec2f(0, 0), 0.0f, 1.0f, 5, gravity, true);
}