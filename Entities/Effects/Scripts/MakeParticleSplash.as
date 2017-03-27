f32 partsplash_randomFloat(f32 range)
{
	return f32(XORRandom(512)) / 512.0f * range;
}

void MakeParticleSplash(const string &in file, s32 xchunk, s32 ychunk, const Vec2f &in pos, f32 vel = 4.0f, s32 team = 0)
{
	s32 style_8_first = xchunk * 4;
	s32 frame_8_first = ychunk * 4;

	s32 style_16_first = xchunk * 2;
	s32 frame_16_first = ychunk * 2;

	//TODO: sound for all

	//first tiny chunks

	f32 angle = 90;
	f32 spread = 80.0f;

	makeGibParticle(CFileMatcher(file).getRandom(), pos,
	                getRandomVelocity(angle, vel + partsplash_randomFloat(2.0f), spread),
	                style_8_first, frame_8_first,
	                Vec2f(8, 8), 1.0f, 0, "", team);

	makeGibParticle(CFileMatcher(file).getRandom(), pos,
	                getRandomVelocity(angle, vel + partsplash_randomFloat(1.0f), spread),
	                style_8_first + 1, frame_8_first,
	                Vec2f(8, 8), 1.0f, 0, "", team);

	makeGibParticle(CFileMatcher(file).getRandom(), pos,
	                getRandomVelocity(angle, vel + partsplash_randomFloat(3.0f), spread),
	                style_8_first, frame_8_first + 1,
	                Vec2f(8, 8), 1.0f, 0, "", team);

	makeGibParticle(CFileMatcher(file).getRandom(), pos,
	                getRandomVelocity(angle, vel + partsplash_randomFloat(2.0f), spread),
	                style_8_first + 1, frame_8_first + 1,
	                Vec2f(8, 8), 1.0f, 0, "", team);

	//big chunks

	makeGibParticle(CFileMatcher(file).getRandom(), pos,
	                getRandomVelocity(angle, vel + partsplash_randomFloat(1.0f), spread),
	                style_16_first + 1, frame_16_first,
	                Vec2f(16, 16), 1.0f, 0, "", team);

	makeGibParticle(CFileMatcher(file).getRandom(), pos,
	                getRandomVelocity(angle, vel, spread),
	                style_16_first, frame_16_first + 1,
	                Vec2f(16, 16), 1.0f, 0, "", team);

	// kinda funky chunk: 2 1x1, 1 1x2

	makeGibParticle(CFileMatcher(file).getRandom(), pos,
	                getRandomVelocity(angle, vel + partsplash_randomFloat(2.0f), spread),
	                style_8_first + 2, frame_8_first + 2,
	                Vec2f(8, 8), 1.0f, 0, "", team);

	makeGibParticle(CFileMatcher(file).getRandom(), pos,
	                getRandomVelocity(angle, vel + partsplash_randomFloat(3.0f), spread),
	                style_8_first + 2, frame_8_first + 3,
	                Vec2f(8, 8), 1.0f, 0, "", team);

	makeGibParticle(CFileMatcher(file).getRandom(), pos,
	                getRandomVelocity(angle, vel + partsplash_randomFloat(2.0f), spread),
	                style_8_first + 3, frame_16_first + 1,
	                Vec2f(8, 16), 1.0f, 0, "", team);


}
