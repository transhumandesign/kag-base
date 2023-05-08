void MakeDustParticle(Vec2f pos, string file)
{
	CParticle@ temp = ParticleAnimated(CFileMatcher(file).getFirst(), pos - Vec2f(0, 8), Vec2f(0, 0), 0.0f, 1.0f, 3, 0.0f, false);

	if (temp !is null)
	{
		temp.width = 8;
		temp.height = 8;
	}
}

void MakeRockDustParticle(Vec2f pos, string file, Vec2f vel=Vec2f(0.0, 0.0), int animate_speed = 4)
{
	Random _r(XORRandom(9999)); // pain
	CParticle@ temp = ParticleAnimated(CFileMatcher(file).getFirst(), pos, vel, 0.0f, 1.0f, animate_speed, 0.0f, false);

	if (temp !is null)
	{
		temp.rotation = Vec2f(-1, 0);
		temp.rotation.RotateBy(_r.NextFloat() * 360.0f);
		temp.rotates = true;

		temp.width = 8;
		temp.height = 8;
	}
}