
const int ABSORB_COUNT = 100;
const string ABSORBED_PROP = "absorbed";


void spongeUpdateSprite(CSprite@ this, u8 absorbed)
{
	this.animation.setFrameFromRatio(f32(absorbed) / ABSORB_COUNT);
}